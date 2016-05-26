# -*- encoding : utf-8 -*-
require "#{File.join(File.dirname(__FILE__), '../ffi', 'win32_kernel32')}"
module WoolenCommon
    module WindowsMonitor

        MIB_IFROW = 4
        MIB_IFROW_SIZE = 860 #MIB_IFROW结构体大小
        MIB_IFROW_dwIndex = 512
        MIB_IFROW_OutOctets = 576 #dwOutOctets位置偏移
        MIB_IFROW_InOctets = 552 #dwInOctets位置偏移

        MIB_IFTABLE_SIZE = 28392 #MIB_IFTABLE结构体大小

        IP_ADAPTER_ADDRESSES_SIZE = 4044 #IP_ADAPTER_ADDRESSES结构体大小
        FRIENDLY_NAME = 26412 #本地连接字符串转成short
        IP_ADAPTER_ADDRESSES_FriendlyName = 40 #接口名称偏移
        IP_ADAPTER_ADDRESSES_IfIndex = 4 #接口索引偏移
        IP_ADAPTER_ADDRESSES_Next = 8 #下一个结构体Next字段偏移
		

        def compare_file_time(time1, time2)
            a = time1[:dwHighDateTime] << 32 | time1[:dwLowDateTime]
            b = time2[:dwHighDateTime] << 32 | time2[:dwLowDateTime]
            b - a
        end

        def get_system_cpu_usage(time=1)
            p_idle_time = FFI::MemoryPointer.new(Win32Kernel32::Filetime.size)
            p_kernel_time = FFI::MemoryPointer.new(Win32Kernel32::Filetime.size)
            p_user_time = FFI::MemoryPointer.new(Win32Kernel32::Filetime.size)
            idle_time = Win32Kernel32::Filetime.new p_idle_time
            kernel_time = Win32Kernel32::Filetime.new p_kernel_time
            usr_time = Win32Kernel32::Filetime.new p_user_time
            p_pre_idle_time = FFI::MemoryPointer.new(Win32Kernel32::Filetime.size)
            p_pre_kernel_time = FFI::MemoryPointer.new(Win32Kernel32::Filetime.size)
            p_pre_user_time = FFI::MemoryPointer.new(Win32Kernel32::Filetime.size)
            pre_idle_time = Win32Kernel32::Filetime.new p_pre_idle_time
            pre_kernel_time = Win32Kernel32::Filetime.new p_pre_kernel_time
            pre_usr_time = Win32Kernel32::Filetime.new p_pre_user_time
            Win32Kernel32.getSystemTimes(p_pre_idle_time, p_pre_kernel_time, p_pre_user_time)
            sleep time
            Win32Kernel32.getSystemTimes(p_idle_time, p_kernel_time, p_user_time)
            idle = compare_file_time(pre_idle_time, idle_time)
            ker = compare_file_time(pre_kernel_time, kernel_time)
            usr = compare_file_time(pre_usr_time, usr_time)
            (ker + usr - idle) *100 / (ker + usr)
        end

        def get_system_mem_usage
            p_ms_adder= FFI::MemoryPointer.new(Win32Kernel32::MemoryStatus.size)
            p_ms = Win32Kernel32::MemoryStatus.new p_ms_adder
            Win32Kernel32.globalMemoryStatus(p_ms);
            p_ms[:dwMemoryLoad]
        end

        def get_system_disk_info
            sz_driver = FFI::MemoryPointer.from_string('\\\\.\\PhysicalDrive0')
            ptr1 = FFI::MemoryPointer.new(:uint)
            ptr2 = FFI::MemoryPointer.new(:uint)
            junk1 = 0
            junk2 = 0
            p_disk_perform_adder1= FFI::MemoryPointer.new(Win32Kernel32::Disk_Perfomance.size)
            p_disk_perform1 = Win32Kernel32::Disk_Perfomance.new p_disk_perform_adder1
            h_device = Win32Kernel32.createFileA(sz_driver, 0, Win32Kernel32::OPEN_EXISTING, 0, Win32Kernel32::OPEN_EXISTING, 0, 0)
            Win32Kernel32.deviceIoControl(h_device, Win32Kernel32::IOCTL_DISK_PERFORMANCE, 0, 0, p_disk_perform1, Win32Kernel32::Disk_Perfomance.size, ptr1, 0);
            puts "BytesRead:#{p_disk_perform1[:BytesRead]} BytesWritten:#{p_disk_perform1[:BytesWritten]} ReadCount:#{p_disk_perform1[:ReadCount]} WriteCount:#{p_disk_perform1[:WriteCount]}"
            sleep 1
            p_disk_perform_adder2= FFI::MemoryPointer.new(Win32Kernel32::Disk_Perfomance.size)
            p_disk_perform2 = Win32Kernel32::Disk_Perfomance.new p_disk_perform_adder2
            Win32Kernel32.deviceIoControl(h_device, Win32Kernel32::IOCTL_DISK_PERFORMANCE, 0, 0, p_disk_perform2, Win32Kernel32::Disk_Perfomance.size, ptr2, 0);
            #puts "BytesRead:#{p_disk_perform2[:BytesRead]} BytesWritten:#{p_disk_perform2[:BytesWritten]} ReadCount:#{p_disk_perform2[:ReadCount]} WriteCount:#{p_disk_perform2[:WriteCount]}"
            ret_disk_arr =[]
            ret_disk_arr << (p_disk_perform2[:BytesRead] - p_disk_perform1[:BytesRead])/1000.to_f
            ret_disk_arr << (p_disk_perform2[:BytesWritten] - p_disk_perform1[:BytesWritten])/1000.to_f
            ret_disk_arr << p_disk_perform2[:ReadCount] - p_disk_perform1[:ReadCount]
            ret_disk_arr << p_disk_perform2[:WriteCount] - p_disk_perform1[:WriteCount]
            ret_disk_arr
        end


        #返回数组发送字节/S和接受字节每秒
        def get_system_network_info(net_if_ids)
            ret_arr = []
            net_if_ids.each do |one_if_id|
                pre_net_arr = get_network_info_by_index(one_if_id.to_i)
                sleep 1
                next_net_arr = get_network_info_by_index(one_if_id.to_i)
                ret_arr << (next_net_arr[0] - pre_net_arr[0]) #发送字节数/秒
                ret_arr << (next_net_arr[1] - pre_net_arr[1]) #接收字节数/秒
            end
            ret_arr
        end

        #通过本地连接的索引获取本地连接接口发送和接受字节数组
        def get_network_info_by_index(index=14)
            net_arr = []
            ptr_iftable = FFI::MemoryPointer.new(MIB_IFTABLE_SIZE)
            iftable_size_ptr = FFI::MemoryPointer.new(:uint)
            iftable_size = MIB_IFTABLE_SIZE
            iftable_size_ptr.write_uint iftable_size
            iftable_size_ptr.read_uint
            dw_ret = Win32Kernel32.getIfTable(ptr_iftable, iftable_size_ptr, 0)
            dw_num = ptr_iftable.read_uint
            pifrow_start = (ptr_iftable + MIB_IFROW)
            pifrow_end = pifrow_start + dw_num * MIB_IFROW_SIZE
            while pifrow_start.address < pifrow_end.address do
                if_index = (pifrow_start + MIB_IFROW_dwIndex).read_uint
                if if_index == index
                    out_bytes = (pifrow_start + MIB_IFROW_OutOctets).read_uint
                    in_bytes = (pifrow_start + MIB_IFROW_InOctets).read_uint
                    net_arr << out_bytes
                    net_arr << in_bytes
                    break
                end
                pifrow_start = pifrow_start + MIB_IFROW_SIZE
            end
            net_arr

        end

        def get_common_performance(monitor_cfg)
            performance_hash = {}
            performance_hash['cpu'] = get_system_cpu_usage
            performance_hash['memory'] = get_system_mem_usage

            ret_disk = get_system_disk_info
            if ret_disk
                performance_hash['r_kBps'] = ret_disk[0]
                performance_hash['w_kBps'] = ret_disk[1]
                performance_hash['r_iops'] = ret_disk[2]
                performance_hash['w_iops'] = ret_disk[3]
            end
            net_disk = get_system_network_info(monitor_cfg['net_if_ids'])
            if net_disk
                performance_hash['net_tx_bytes'] = net_disk[0]
                performance_hash['net_rx_bytes'] = net_disk[1]
            end
            performance_hash
        end

        def self.included(base)
            base.extend self
        end
    end
end