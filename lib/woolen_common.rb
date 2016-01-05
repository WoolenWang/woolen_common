# -*- encoding : utf-8 -*-
require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'version')}"
require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'actionpool')}"
require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'config_manager')}"

module WoolenCommon

    def setup(prj_root=nil)
        unless prj_root
            prj_root = File.dirname caller[0].split(':')[0]
        end
        ConfigManager.project_root = prj_root
        puts "the prj_root:#{prj_root}"
        load_all_file
    end

    def load_all_file
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'ruby_ext', 'string')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'ruby_ext', 'blank')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'ruby_ext', 'drb_ext')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'ruby_ext', 'win32_ole')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'common_helper')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'addr_helper')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'type_helper')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'logger')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'system_helper')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'system_monitor')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'splib')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'action_pool_proxy')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'ssh_proxy')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'drb_helper')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'pcap', 'pcap')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'ver_ctrl_middle_ware')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'ruby_proxy')}"
        require "#{File.join(File.dirname(__FILE__), 'woolen_common', 'cache')}"
    end

    module_function :setup,:load_all_file
end
