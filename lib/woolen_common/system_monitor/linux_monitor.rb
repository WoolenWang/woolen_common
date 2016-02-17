# -*- encoding : utf-8 -*-
module WoolenCommon
    module LinuxMonitor
        include WoolenCommon::ToolLogger
        LINUX_CPU_STAT='/proc/stat'
        LINUX_MEM_STAT='/proc/meminfo'
        LINUX_DISK_STAT='/proc/diskstats'
        LINUX_DISK_PARTITION_STAT='/proc/partitions'
        SYS_NET_PATH = '/sys/class/net'

        CPU_STAT_FORMAT = %w{cpu user nice system idle io_wait irq soft_irq steal guest}
        DISK_STAT_FORMAT = %w{disk r_io/s w_io/s r_kB/s w_kB/s r_size w_size}

        # cpu 432661    13295   86656       422145968   171474      233     5346        0               0
        # cpu {user}    {nice}  {system}    {idle}      {iowait}    {irq}   {softirq}   {stealstolen}   {guest}
        # user (432661) 从系统启动开始累计到当前时刻，用户态的CPU时间（单位：jiffies） ，不包含 nice值为负进程。1jiffies=0.01秒
        #nice (13295) 从系统启动开始累计到当前时刻，nice值为负的进程所占用的CPU时间（单位：jiffies）
        #system (86656) 从系统启动开始累计到当前时刻，核心[系统调用]时间（单位：jiffies）
        #idle (422145968) 从系统启动开始累计到当前时刻，除硬盘IO等待时间以外其它等待时间（单位：jiffies）
        #iowait (171474) 从系统启动开始累计到当前时刻，硬盘IO等待时间（单位：jiffies） ，
        #irq (233) 从系统启动开始累计到当前时刻，硬中断时间（单位：jiffies）
        #softirq (5346) 从系统启动开始累计到当前时刻，软中断时间（单位：jiffies）
        #stealstolen(0)     which is the time spent in other operating systems when running in a virtualized environment(since 2.6.11)
        #guest(0)        which is the time spent running a virtual  CPU  for  guest operating systems under the control of the Linux kernel(since 2.6.24)
        def get_one_cpu_usage(old, new)
            ret_hash = {}
            old_array = old.split(/\s+/)
            new_array = new.split(/\s+/)
            # trace "old[#{old}] split #{old_array}"
            # trace "new[#{new}] split #{new_array}"
            old_sum = 0
            new_sum = 0
            old_array.each { |str| old_sum += str.to_i }
            new_array.each { |str| new_sum += str.to_i }
            delta_sum = (new_sum - old_sum).to_f
            ideal_delta = new_array[4].to_i - old_array[4].to_i
            # debug "length #{new_array.length} old sum[#{old_sum}] new_sum[#{new_sum}] delta_sum[#{delta_sum}] ideal_delta[#{ideal_delta}]"
            ret_hash['total'] = ((1 - (ideal_delta) / (delta_sum)) * 100).round(3)
            0.upto CPU_STAT_FORMAT.length-1 do |cnt|
                # debug "checking cnt[#{cnt}]"
                if new_array[cnt]
                    if cnt == 0
                        ret_hash[CPU_STAT_FORMAT[cnt]] = new_array[cnt]
                    else
                        delta = new_array[cnt].to_i - old_array[cnt].to_i
                        # debug "cpu [#{CPU_STAT_FORMAT[cnt]}] delta #{delta}"
                        ret_hash[CPU_STAT_FORMAT[cnt]] = (((delta) / (delta_sum)) * 100).round(3)
                    end
                else
                    debug "not have #{CPU_STAT_FORMAT[cnt]} cnt[#{cnt}]"
                end
            end
            ret_hash
        end

        def get_system_cpu_usage(time=1)
            result = []
            old_arry = File.open(LINUX_CPU_STAT, 'r') { |f| f.read.split("\n") }
            sleep time
            new_arry = File.open(LINUX_CPU_STAT, 'r') { |f| f.read.split("\n") }
            0.upto old_arry.length do |cnt|
                if old_arry[cnt] =~ /^cpu/
                    the_cpu_usage = get_one_cpu_usage old_arry[cnt].strip, new_arry[cnt].strip
                    result << the_cpu_usage
                end
            end
            result
        end

        def get_system_mem_usage
            mem_array = File.open(LINUX_MEM_STAT, 'r') { |f| f.read.split("\n") }
            total_mem = 0
            available_mem = 0
            mem_array.each do |one_line|
                line = one_line.strip.downcase
                case line
                    when /MemTotal/i
                        total_mem = line.gsub(/\D/, '').to_i
                        debug "total mem #{total_mem}"
                    when /MemFree/i
                        available_mem = line.gsub(/\D/, '').to_i
                        debug "available_mem #{available_mem}"
                    else
                        trace "line[#{line}]"
                end
            end

            if total_mem > 0
                ((total_mem - available_mem) / total_mem.to_f * 100).round 3
            else
                error "can not get total mem from #{mem_array}"
                nil
            end
        end


        def get_one_disk_status(old_line, new_line, delta_time)
            old_arr = old_line.split(/\s+/)
            new_arr = new_line.split(/\s+/)
            new = new_arr.drop(2)
            old = old_arr.drop(2)
            block_size = File.open("/sys/dev/block/#{new_arr[0]}:#{new_arr[1]}/queue/logical_block_size", 'r') { |f| f.read }.to_i
            if old[0] != new[0]
                error "wrong dis check line old[#{old_line}] new[#{new_line}]"
            end
            r_iops = ((new[1].to_i - old[1].to_i) / delta_time).round(2)
            w_iops = ((new[5].to_i - old[5].to_i) / delta_time).round(2)
            r_sec_s = ((new[3].to_i - old[3].to_i) / delta_time).round(2)
            w_sec_s = ((new[7].to_i - old[7].to_i) / delta_time).round(2)
            debug "r_iops[#{r_iops}],w_iops[#{w_iops}],r_sec_s[#{r_sec_s}],w_sec_s[#{w_sec_s}],block_size[#{block_size}]"
            r_kb_s = r_sec_s * block_size / 8
            w_kb_s = w_sec_s * block_size / 8
            if r_iops == 0
                r_size = 0
            else
                r_size = r_kb_s / r_iops
            end
            if w_iops == 0
                w_size = 0
            else
                w_size = w_kb_s / w_iops
            end
            {
                'disk' => new[0],
                'r_io/s' => r_iops,
                'w_io/s' => w_iops,
                'r_kB/s' => r_kb_s,
                'w_kB/s' => w_kb_s,
                'r_size' => r_size,
                'w_size' => w_size
            }
        end

        def get_disk_hash
            real_disk = {}
            disk_array = File.open(LINUX_DISK_PARTITION_STAT, 'r') { |f| f.read.split("\n") }
            0.upto(disk_array.length-1) do |cnt|
                unless cnt == 0
                    one_arr = disk_array[cnt].strip.split(/\s+/)
                    trace "str[#{disk_array[cnt].strip}]one arr #{one_arr}"
                    if one_arr[1] == '0'
                        if real_disk[one_arr[3]]
                            warn "already get disk #{one_arr[3]} id #{real_disk[one_arr[3]]}"
                        else
                            real_disk[one_arr[3]] = one_arr[0]
                        end
                    end
                end
            end
            real_disk
        end

        def get_io_status(time=5)
            result = []
            disk_hash = get_disk_hash
            old_disk_arr = File.open(LINUX_DISK_STAT, 'r') { |f| f.read.split("\n") }.each { |one| one.strip! }
            old_time = Time.now.to_i
            sleep time
            new_disk_arr = File.open(LINUX_DISK_STAT, 'r') { |f| f.read.split("\n") }.each { |one| one.strip! }
            new_time = Time.now.to_i
            disk_hash.each do |one_disk, disk_id|
                0.upto(old_disk_arr.length - 1) do |cnt|
                    if old_disk_arr[cnt] =~ Regexp.new("^#{disk_id}\\s+0\\s+#{one_disk}")
                        result << get_one_disk_status(old_disk_arr[cnt], new_disk_arr[cnt], (new_time - old_time))
                    end
                end
            end
            result
        end

        def get_net_name(filepath=SYS_NET_PATH)
            net_name = []
            if File.directory?(filepath)
                Dir.foreach(filepath) do |filename|
                    if filename != "." and filename != ".." and filename != "lo"
                        net_name << filename
                    end
                end
            else
                puts "Files:" + filepath
            end
            net_name
        end


        def get_net_bytes
            net_name = get_net_name
            hash_tmp = {}
            net_name.each do |one_name|
                hash_tmp[one_name] = {}
                File.open("/sys/class/net/#{one_name}/statistics/tx_bytes", 'r') do |f|
                    hash_tmp[one_name]['tx_bytes'] = f.read.strip
                end
                File.open("/sys/class/net/#{one_name}/statistics/rx_bytes", 'r') do |f|
                    hash_tmp[one_name]['rx_bytes'] = f.read.strip
                end
            end
            hash_tmp
        end

        def get_system_net_speed
            old_hash = get_net_bytes
            puts old_hash

            sleep 1
            new_hash = get_net_bytes
            puts new_hash
            hash_tmp = {}
            new_hash.each do |key, value|
                hash_tmp[key] = {}
                hash_tmp[key]['tx_bytes'] = value['tx_bytes'].to_i - old_hash[key]['tx_bytes'].to_i
                hash_tmp[key]['rx_bytes'] = value['rx_bytes'].to_i - old_hash[key]['rx_bytes'].to_i
            end
            hash_tmp
        end

        def get_common_performance
            performance_hash = {}
            performance_hash['cpu'] = get_system_cpu_usage[0]['total']
            performance_hash['memory'] = get_system_mem_usage

            ret_disk_arr = get_io_status
            if ret_disk_arr
                performance_hash['r_iops'] = ret_disk_arr[0]['r_io/s']
                performance_hash['w_iops'] = ret_disk_arr[0]['w_io/s']
                performance_hash['r_kBps'] = ret_disk_arr[0]['r_kB/s']
                performance_hash['w_kBps'] = ret_disk_arr[0]['w_kB/s']
            end

            #get_system_net_speed获取所有网卡的传输速率，前台仅显示eth0的速率
            ret_net_hash = get_system_net_speed
            if ret_net_hash
                performance_hash['net_tx_bytes'] = ret_net_hash['eth0']['tx_bytes']
                performance_hash['net_rx_bytes'] = ret_net_hash['eth0']['rx_bytes']
            end
            performance_hash
        end


        def self.included(base)
            base.extend self
        end

        module_function :get_system_cpu_usage
    end
end