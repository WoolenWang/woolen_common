# -*- encoding : utf-8 -*-
require "#{File.join(File.dirname(__FILE__), 'logger')}"
require "#{File.join(File.dirname(__FILE__), 'common_helper')}"
require "#{File.join(File.dirname(__FILE__), 'type_helper')}"
require 'ipaddr'
module WoolenCommon
    class AddrHelper
        class << self
            include WoolenCommon::ToolLogger
            # IP地址字符串转做数值(无符号的)
            def ip_str_to_unsigned(ip_addr_str)
                IPAddr.new(ip_addr_str).to_i
            end

            # IP地址字符串转做数值(有符号的)
            def ip_str_to_signed(ip_addr_str,byte_length=32)
                begin
                    return TypeHelper.to_signed(IPAddr.new(ip_addr_str).to_i, byte_length)
                rescue Exception=>e
                    debug "对IP地址[#{ip_addr_str}]，进行转换到有符号数字出错::#{e.message}"
                    return 0
                end
            end

            # 有符号地址值转成ip字符串
            def signed_to_ip_str(signed,byte_length=32)
                unsigned_32 = TypeHelper.to_unsigned(signed,byte_length)
                IPAddr.new(unsigned_32,Socket::AF_INET).to_s
            end

            # 无符号地址值转成ip字符串
            def unsigned_to_ip_str(unsigned_32)
                IPAddr.new(unsigned_32,Socket::AF_INET).to_s
            end

            # mac地址字符串转成无符号数字数组
            def mac_str_to_array(mac_str)
                if mac_str.kind_of? String
                    if mac_str.include? ':'
                        split_arry = mac_str.split ':'
                    elsif mac_str.include? '-'
                        split_arry = mac_str.split '-'
                    elsif mac_str.length == 12
                        split_arry = []
                        6.times do |cnt|
                            split_arry << mac_str[(2 * cnt)... (2 * (cnt+1))]
                        end
                    else
                        debug "not support mac format:[#{mac_str}],please use : or - format"
                        return []
                    end
                    if split_arry.length != 6
                        debug "to long format:[#{mac_str}]~"
                        return []
                    end
                    return_array=[]
                    split_arry.each do |split_str|
                        return_array << split_str.to_i(16)
                    end
                    return_array
                else
                    error "not support not string format:[#{mac_str}],please give me a mac string"
                end
            end

            # mac地址无符号数字数组转字符串
            def array_to_mac_str(mac_array,str_gap=':')
                debug "start to get mac str from mac array :: #{mac_array}"
                if mac_array.kind_of? Array
                    if mac_array.length != 6
                        error "wrong long arry :[#{mac_array}]~"
                        return ''
                    else
                        ret_str_array = []
                        mac_array.each do |mac_int_x16|
                            mac_value = TypeHelper.get_low_bit_num(mac_int_x16,8)
                            if mac_value >= 16
                                ret_str_array << mac_value.to_s(16)
                            elsif mac_value >= 0 && mac_int_x16 < 16
                                ret_str_array << "0#{mac_value.to_s(16)}"
                            end
                        end
                        debug "success get mac str ::#{ret_str_array.join str_gap}"
                        return ret_str_array.join str_gap
                    end
                else
                    error "not a array mac please give me a array::#{mac_array}~"
                    ''
                end
            end
        end
    end
end
