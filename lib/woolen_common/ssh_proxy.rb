# -*- encoding : utf-8 -*-
begin
    require 'net/ssh' rescue nil
    require 'net/sftp' rescue nil
    require 'woolen_common/connection_pool'
    require "#{File.join(File.dirname(__FILE__), 'logger')}"
    module WoolenCommon
        class SshProxyPool
            include WoolenCommon::ToolLogger

            class << self
                attr_accessor :the_ssh_instances
                def get_ssh_proxy(ip, user, password, port=22, max_ssh=10, time_out=10)
                    @the_ssh_instances ||= {}
                    @the_ssh_instances[ip] ||= {}
                    @the_ssh_instances[ip][port] ||= {}
                    @the_ssh_instances[ip][port][user] ||= {}
                    @the_ssh_instances[ip][port][user][password] ||= self.new(ip, user, password, port=22, max_ssh=10, time_out=10)
                    @the_ssh_instances[ip][port][user][password]
                end
            end

            def initialize(ip, user, password, port=22, max_ssh=10, time_out=10)
                debug "ssh setup : [ user::#{user},password::#{password},port:#{port} ]"
                @ip = ip
                @user = user
                @password = password
                @port = port
                @max_ssh = max_ssh
                @time_out = time_out
                get_pool
            end

            def get_pool
                @ssh_connection_pool ||= ::WoolenCommon::ConnectionPool.new({:size => @max_ssh, :timeout => @time_out}) do
                    debug "ip:#{@ip},@password:#{@password},@port:#{@port}"
                    ::WoolenCommon::SshProxy.new(@ip, @user, :password => @password, :port => @port)
                end
            end

            def method_missing(method, *args, &block)
                debug "need to invoke ssh method ::#{method} #{args}"
                self.instance_eval <<-THE_END
                    def #{method}(*args,&block)
                        trace "need to invoke ssh method ::#{method} \#{args}"
                        get_pool.with do |ssh_conn|
                            return ssh_conn.send :#{method}, *args, &block
                        end
                    end
                THE_END
                self.send method, *args, &block
            end
        end

        class SshProxy
            include WoolenCommon::ToolLogger
            class << self

                attr_accessor :the_ssh_instances
                def get_ssh_proxy(ip,port,user,passwd)
                    options = {:port => port,:password => passwd}
                    @the_ssh_instances ||= {}
                    @the_ssh_instances[ip] ||= {}
                    @the_ssh_instances[ip][port] ||= {}
                    @the_ssh_instances[ip][port][user] ||= {}
                    @the_ssh_instances[ip][port][user][passwd] ||= SshProxy.new(ip, user, options)
                    @the_ssh_instances[ip][port][user][passwd]
                end
            end

            def initialize(host, user, options={})
                @host = host
                @user = user
                @options = options
                @conn_retry = options[:proxy_conn_retry] || 5
                options.delete :proxy_conn_retry if options[:proxy_conn_retry]
                # 超时时间设置30秒太长了，不是很合理，实际上5秒没有回复，那就是出问题了
                @conn_timeout = options[:proxy_conn_timeout] || 5
                options.delete :proxy_conn_timeout if options[:proxy_conn_timeout]
                proxy_reset_conn
            end

            def proxy_reset_conn
                @conn_retry.times do
                    begin
                        Timeout.timeout(@conn_timeout) do
                            # if Net::SSH::Version.to_i <= 3_000_000
                            #     @ssh_conn = Net::SSH.start(@host, @user, @options)
                            # else
                            #     @ssh_conn = Net::SSH.start(@host, @user, @options)
                            # end
                            @ssh_conn = Net::SSH.start(@host, @user, @options)
                            if check_connector_close
                                debug 'reconnect ssh ok'
                                return
                            end
                        end
                    rescue Exception => e
                        error "连接ssh服务器出错~!信息是:#{e.message},用户信息:@host:#{@host},@user:#{@user},@options:#{@options}"
                    end
                end
            end

            def method_missing(name, *args, &block)
                if check_connector_close
                    @ssh_conn.close rescue nil
                    proxy_reset_conn
                end
                #debug "SshProxy need to invoke methdo ::#{name} "
                #debug "params::#{args}"
                Timeout.timeout(@conn_timeout) do
                    return_result = ''
                    if @ssh_conn
                        return_result = @ssh_conn.send(name, *args, &block)
                        #debug "SshProxy invoke result ::#{return_result}"
                    else
                        error 'ssh链接建立不起来！'
                    end
                    return return_result
                end
            end

            def exec!(command, &block)
                if check_connector_close
                    @ssh_conn.close rescue nil
                    proxy_reset_conn
                end
                Timeout.timeout(@conn_timeout) do
                    return @ssh_conn.exec!(command.unpack('C*').pack('C*'), &block)
                end
            end

            def exec(command, &block)
                if check_connector_close
                    @ssh_conn.close rescue nil
                    proxy_reset_conn
                end
                Timeout.timeout(@conn_timeout) do
                    return @ssh_conn.exec(command.unpack('C*').pack('C*'), &block)
                end
            end

            def check_connector_close
                begin
                    if @ssh_conn.nil? or @ssh_conn.closed?
                        return true
                    end
                    Timeout.timeout(@conn_timeout) do
                        if @ssh_conn.exec!('echo hello').include? 'hello'
                            return false
                        end
                    end
                rescue Exception => e
                    error "检查连接出错，错误信息是：：#{e.message}"
                    return true
                end
                true
            end

            # 阻塞性下载
            def sftp_download!(remote_path, local_path)
                if check_connector_close
                    @ssh_conn.close rescue nil
                    proxy_reset_conn
                end
                @ssh_conn.sftp.connect! do |sftp_session|
                    return sftp_session.download!(remote_path, local_path)
                end
            end

            # 非塞性下载
            def sftp_download(remote_path, local_path)
                if check_connector_close
                    @ssh_conn.close rescue nil
                    proxy_reset_conn
                end
                @ssh_conn.sftp.connect do |sftp_session|
                    return sftp_session.download!(remote_path, local_path)
                end
            end

            def sftp_upload!(remote_path, local_path)
                if check_connector_close
                    @ssh_conn.close rescue nil
                    proxy_reset_conn
                end
                @ssh_conn.sftp.connect! do |sftp_session|
                    return sftp_session.upload!(local_path,remote_path)
                end
            end

            def sftp_upload(remote_path, local_path)
                if check_connector_close
                    @ssh_conn.close rescue nil
                    proxy_reset_conn
                end
                @ssh_conn.sftp.connect do |sftp_session|
                    return sftp_session.upload(local_path,remote_path)
                end
            end
        end
    end
rescue Exception => e
    puts "error when load ssh,sftp,no ssh can use #{e.message}"
end
