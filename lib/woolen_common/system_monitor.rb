# -*- encoding : utf-8 -*-
require "#{File.join(File.dirname(__FILE__), 'logger')}"
require "#{File.join(File.dirname(__FILE__), 'system_helper')}"
module WoolenCommon
    class SystemMonitor
        if SystemHelper.windows?
            require "#{File.join(File.dirname(__FILE__), 'system_monitor','windows_monitor')}"
            include WindowsMonitor
        else
            require "#{File.join(File.dirname(__FILE__), 'system_monitor','linux_monitor')}"
            include LinuxMonitor
        end

        class << self
            def run_monitor
                puts get_system_cpu_usage
                puts "mem usage[#{get_system_mem_usage}%]"
                puts "disk usage[#{get_io_status}%]"
            end
        end
    end
end