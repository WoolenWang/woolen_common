# -*- encoding : utf-8 -*-
module WoolenCommon
    module SystemHelper
        IPV4_REGEX = /^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$/

        def ruby18?
            RUBY_VERSION =~ /^1.8/ ? true : false
        end

        module_function :ruby18?

        def ruby19?
            RUBY_VERSION =~ /^1.9/ ? true : false
        end

        module_function :ruby19?

        def platform
            case RUBY_PLATFORM
                when /w32/, /mswin32/
                    "windows"
                when /linux/
                    "linux"
                else
                    "mac"
            end
        end

        module_function :platform

        def windows?
            case RUBY_PLATFORM
                when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                    return true
                when /java/
                    begin
                      require 'Win32API'
                      return true
                    rescue Exception
                      return false
                    end
                else
                    return false
            end
        end

        module_function :windows?

        def is_x64?
            case RUBY_PLATFORM
                when /x86_64/
                    return true
                else
                    return false
            end
        end

        module_function :is_x64?


        def get_local_ip_addrs
            result_array = []
            if windows?
                ip_addr_arrays = TCPSocket.gethostbyname(Socket.gethostname)
                ip_addr_arrays.each do |one_addr|
                    if one_addr.is_a? String
                        if one_addr =~ IPV4_REGEX
                            result_array << one_addr
                        end
                    end
                end
            else
                output = %x{ip addr list}
                output.split(/\n/).each { |str|
                    if str =~ /inet ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/
                        tmp = $1
                        unless tmp =~ /127\./
                            result_array << tmp
                        end
                    end
                }
            end
            result_array
        end

        module_function :get_local_ip_addrs


        def get_same_subnet_ip(check_ip)
            same_count = 0
            ip_size = 32
            ctrl_ip_num = IPAddr.new(check_ip).to_i
            result_ip = ''
            get_local_ip_addrs.each do |one_ip|
                cnt = 0
                one_ip_num = IPAddr.new(one_ip).to_i
                ip_size.times do |count|
                    mask = 1 << (ip_size - count)
                    if ctrl_ip_num & mask == one_ip_num & mask
                        cnt += 1
                        next if cnt < ip_size
                    end
                    if cnt > same_count
                        result_ip = one_ip
                        same_count = cnt
                    end
                    break
                end
            end
            result_ip
        end
        module_function :get_same_subnet_ip

        def get_platform_path(*args, &block)
            real_path = CommonHelper.get_real_path(*args, &block)
            if windows?
                real_path.gsub!('/','\\')
            end
            real_path
        end
        module_function :get_platform_path
    end
end
