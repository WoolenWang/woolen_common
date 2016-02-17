# -*- encoding : utf-8 -*-
require "#{File.join(File.dirname(__FILE__), 'logger')}"
require "#{File.join(File.dirname(__FILE__), 'system_helper')}"
module WoolenCommon
    class SystemMonitor
        if SystemHelper.windows?
            require "#{File.join(File.dirname(__FILE__), 'system_monitor', 'windows_monitor')}"
            include WindowsMonitor
        else
            require "#{File.join(File.dirname(__FILE__), 'system_monitor', 'linux_monitor')}"
            include LinuxMonitor
        end

        class << self
            def run_monitor
                get_common_performance
            end
        end
    end
end