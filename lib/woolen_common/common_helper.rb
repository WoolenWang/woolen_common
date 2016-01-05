# -*- encoding : utf-8 -*-
require "#{File.join(File.dirname(__FILE__), 'logger')}"
module WoolenCommon
    class CommonHelper
        include WoolenCommon::ToolLogger

        class << self
            def wait_until_stopped
                info 'Press ENTER or c-C to stop it'
                $stdout.flush
                begin
                    loop do
                        sleep 1
                    end
                rescue Interrupt
                    info 'Interrupt'
                end
            end

            def run_project_bin(program,param_str)
                program_name = get_real_path(WoolenCommon::ConfigManager.project_root,'bin',program)
                trace "need to run bin [#{program_name} #{param_str}]"
                if WoolenCommon::SystemHelper.windows?
                    cmd = "#{program_name} #{param_str}".to_gbk
                    `#{cmd}`.to_utf8
                else
                    cmd = "#{program_name} #{param_str}"
                    `#{cmd}`
                end
            end

            def get_real_path(*args, &block)
                file_path = File.expand_path(File.join(*args))
                if block_given?
                    yield block file_path
                    return file_path
                end
                file_path
            end
        end
    end
end
