# -*- encoding : utf-8 -*-
require 'drb'
require "#{File.join(File.dirname(__FILE__), 'logger')}"
module WoolenCommon
    SERVER_DEFAULT_PORT = 108801
    CLIENT_DEFAULT_PORT = 108802
    DEFAULT_CLIENT_ADDR = '127.0.0.1'
    module DrbHelp
        def get_rand_port
            rand(55534) + 8000
        end
        def get_drb_connect_obj(connect_str)
            begin
                DRbObject.new_with_uri(connect_str)
            rescue Exception=>e
                error "获取客户端的连接信息时出错：：#{e.message}"
                return nil
            end
        end

        def ip_or_iport_with_default(ip_or_iport, default_port)
            default_port = default_port.to_s
            if ! ip_or_iport.include?(':')
                iport = ip_or_iport + ':' + default_port
            else
                iport = ip_or_iport
            end
            ip2druby(iport)
        end

        def ip2druby(ip)
            unless ip.include?('://')
                return "druby://" + ip
            end
            ip
        end

        def start_service(service_addr,service_obj = nil)
            if service_obj
                DRb.start_service(service_addr,service_obj)
            else
                DRb.start_service(service_addr)
            end
        end

        module_function :get_drb_connect_obj, :ip_or_iport_with_default, :ip2druby,:start_service,:get_rand_port
    end

    module DrbServerHelper
        include DrbHelp
        include WoolenCommon::ToolLogger

        def server_init(me='127.0.0.1')
            me_drb_addr = ip_or_iport_with_default(me, SERVER_DEFAULT_PORT)
            @worker_connect_array = []
            @worker_connect_array_mutex = Mutex.new
            debug "server need to start #{me_drb_addr}"
            @me_service = start_service(me_drb_addr,self)
        end

        def on_one_worker_connect(worker_ip)
            debug "get one the worker #{worker_ip}"
            worker_connect_str = ip_or_iport_with_default worker_ip,CLIENT_DEFAULT_PORT
            # debug "connect str #{worker_connect_str}"
            worker_connect = get_drb_connect_obj worker_connect_str
            worker_id = 0
            @worker_connect_array_mutex.synchronize do
                @worker_connect_array << worker_connect
                worker_id = @worker_connect_array.length
            end
            worker_id
        end

        # 需要阻塞的时候的阻塞函数
        def wait_until_stopped
            puts 'Flow replay worker started.  Press ENTER or c-C to stop it'
            $stdout.flush
            begin
                STDIN.gets
            rescue Interrupt
                puts "Interrupt"
            end
        end
        module_function :server_init

    end

    module DrbClientHelper
        include DrbHelp
        include WoolenCommon::ToolLogger

        def client_init(server_addr='127.0.0.1',my_port=nil)
            the_port = my_port
            if my_port
                @my_url = "druby://0.0.0.0:#{my_port}"
                @me_service = start_service(@my_url,self)
            else
                100.times do
                    begin
                        port = get_rand_port
                        the_port = port
                        if server_addr == '127.0.0.1'
                            @my_url = "druby://127.0.0.1:#{port}"
                        else
                            @my_url = "druby://0.0.0.0:#{port}"
                        end
                        debug "client need to try url #{@my_url}"
                        @me_service = start_service(@my_url,self)
                        break
                    rescue Exception => e
                        error "在使用随机端口时出错了#{e.message}"
                        retry
                    end
                end
            end
            debug "server addr ::#{server_addr},port#{SERVER_DEFAULT_PORT}"
            server_str = ip_or_iport_with_default(server_addr,SERVER_DEFAULT_PORT)
            @server_service = get_drb_connect_obj(server_str)
            url = "druby://#{DEFAULT_CLIENT_ADDR}:#{the_port}"
            debug "the server#{@server_service}need to invoke worker connect url::#{url}"
            @server_service.on_one_worker_connect(url)
        end
        module_function :client_init
    end
end
