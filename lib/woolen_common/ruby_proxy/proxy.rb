# -*- encoding : utf-8 -*-
require 'drb'
require "#{File.join(File.dirname(__FILE__), 'proxy_load')}"
require "#{File.join(File.dirname(__FILE__), 'proxy_global_set')}"

module RubyProxy
    class Proxy
        include WoolenCommon::ToolLogger
        JOBS_QUEUE = Queue.new
        JOBS_FINISH_ARRAY = []
        JOBS_RETURN_ARRAY = []
        MAX_HANDLE_THREAD = 1
        $__proxy_job_id ||= 0
        class << self
            attr_accessor :worker_flag
        end

        def self.proxy(klass_name, method=nil, *arg)
            job = {}
            job[:klass_name] = Marshal.load(Marshal.dump(klass_name))
            job[:method] = Marshal.load(Marshal.dump(method))
            job[:arg] = Marshal.load(Marshal.dump(arg))
            job[:id] = $__proxy_job_id + 1
            $__proxy_job_id += 1
            JOBS_QUEUE.push job
            job[:id]
        end

        def self.set_work_flag(flag)
            info "setting set_work_flag #{flag}"
            self.worker_flag = flag
        end

        def self.worker_start
            self.worker_flag = true
            MAX_HANDLE_THREAD.times do |cnt|
                debug "starting worker :#{cnt}"
                Thread.new do
                    loop do
                        the_job = nil
                        begin
                            if self.worker_flag
                                the_job = JOBS_QUEUE.pop
                                if the_job
                                    handle_job the_job
                                end
                            else
                                sleep 0.5
                            end
                        rescue Exception => e
                            error "handle job error :#{e}", e
                        end
                    end
                end
            end
        end

        def self.handle_job(job)
            debug "doing job :#{job}"
            klass_name = job[:klass_name]
            method = job[:method]
            arg = job[:arg]
            begin
                if method.nil?
                    ret = proxy_module(klass_name)
                else
                    ret = proxy_module(klass_name).send(method, *arg)
                end
                debug "finish proxy action:#{method}"
                JOBS_RETURN_ARRAY[job[:id]] = ret
                    # return ret
            rescue Exception => e
                error "proxy invoke error:#{e.message}", e
            ensure
                JOBS_FINISH_ARRAY[job[:id]] = true
            end
        end

        def self.is_job_done?(job_id)
            if JOBS_FINISH_ARRAY[job_id]
                true
            else
                false
            end
        end

        def self.get_the_job_ret(job_id)
            the_ret = JOBS_RETURN_ARRAY[job_id]
            JOBS_RETURN_ARRAY[job_id] = nil
            the_ret
        end

        def self.copy_env(env_hash)
            env_hash.each do |key,value|
                if key.blank? || value.blank?
                    info 'try to copy empty_env'
                    next
                end
                ENV["#{key}"] = "#{value}"
            end
            nil
        end

        def self.proxy_load(file_or_gem)
            ProxyLoad.load_file(file_or_gem)
        end

        def self.proxy_global_set(arg, var)
            ProxyGlobalSet.set(arg, var)
        end

        def self.proxy_global_get(arg)
            ProxyGlobalSet.get(arg)
        end

        def self.add_load_path(path)
            ProxyGlobalSet.add("$LOAD_PATH", path)
        end

        def self.proxy_type(klass_name)
            return proxy_const_get(klass_name).class.to_s
        end

        def self.proxy_module(klass_name)
            trace "need to proxy module: [#{klass_name}]"
            m = proxy_const_get(klass_name)
            trace "finish get const class:#{m}"
            m.class_eval {
                include DRb::DRbUndumped
                extend DRb::DRbUndumped
            } if (m.class.to_s == 'Class' or m.class.to_s == 'Module') and !m.include?(DRb::DRbUndumped)
            return m
        end

        def self.proxy_const_get(klass_name)
            atu = nil
            klass_name_array = klass_name.split('::')
            klass_name_array.shift if klass_name_array[0] == 'ATU'
            trace "try to get class :#{klass_name},the class name array:#{klass_name_array}"
            klass_name_array.each do |m|
                if atu.nil?
                    atu = Kernel.const_get(m)
                    trace "get atu: [#{atu}]"
                else
                    trace "get const [#{m}] in atu: [#{atu}]"
                    atu = atu.const_get(m)
                end
            end
            atu
        end

        def self.stop_proxy
            DRb.stop_service
        end

    end
end
