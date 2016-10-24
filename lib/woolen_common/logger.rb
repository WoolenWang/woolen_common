# -*- encoding : utf-8 -*-
require 'logger'
require 'yaml'
require 'fileutils'
require 'pathname'
require "#{File.join(File.dirname(__FILE__), 'system_helper')}"
require "#{File.join(File.dirname(__FILE__), 'config_manager')}"
module WoolenCommon
    class MyLogger # :nodoc: all
        include SystemHelper
        LEVELS = ['TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL']
        COLORS = { 'TRACE' => 'white', 'DEBUG' => 'silver', 'INFO' => 'green', 'WARN' => 'yellow', 'ERROR' => 'purple', 'FATAL' => 'red' }
        FOREGROUND_BLUE = 1
        FOREGROUND_GREEN = 2
        FOREGROUND_RED = 4
        FOREGROUND_INTENSITY = 8
        BACKGROUND_BLUE = 16
        BACKGROUND_GREEN = 32
        BACKGROUND_RED = 64
        BACKGROUND_INTENSITY = 128
        WIN32COLORS = [
            "default", "black", "navy", "green",
            "teal", "maroon", "purple", "olive",
            "silver", "gray", "blue", "lime",
            "aqua", "red", "fuchsia", "yellow",
            "white"
        ]
        WIN32_FOREGROUND_COLOR_MOD = [
            -1, 0,
            FOREGROUND_BLUE, FOREGROUND_GREEN, FOREGROUND_BLUE | FOREGROUND_GREEN,
            FOREGROUND_RED, FOREGROUND_BLUE | FOREGROUND_RED, FOREGROUND_RED | FOREGROUND_GREEN,
            FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED
        ]
        WIN32_BACKGROUND_COLOR_MOD = [
            -1, 0,
            BACKGROUND_BLUE, BACKGROUND_GREEN, BACKGROUND_BLUE | BACKGROUND_GREEN,
            BACKGROUND_RED, BACKGROUND_BLUE | BACKGROUND_RED, BACKGROUND_RED | BACKGROUND_GREEN,
            BACKGROUND_BLUE | BACKGROUND_GREEN | BACKGROUND_RED
        ]
        # WIN_PRINTER = Pathname.new(File.join(__FILE__, '..', '..', '..', 'bin', 'puts_color.exe')).realpath.to_s
        attr_reader :file, :stdout, :name
        attr_accessor :level, :log_cache, :cache_msg, :cache_count

        LOGGERS = []

        def linux_puts_color(message, color = nil)
            case color
                when 'red'
                    color = '31;1'
                when 'green'
                    color = '32;1'
                when 'yellow'
                    color = '33;1'
                when 'blue'
                    color = '34;1'
                when 'purple'
                    color = '35;1'
                when 'silver'
                    color = '36;1'
                when 'white'
                    color = '37;1'
                else
                    color = ''
            end
            if color == ''
                print "#{message}\n"
            else
                print "\e[#{color}m#{message}\e[0m\n"
            end
        end

        def win32_puts_color(message, color)
            require "#{File.join(File.dirname(__FILE__), 'ffi', 'win32_kernel32')}"
            the_out_handle = Win32Kernel32.getStdHandle Win32Kernel32::STD_OUTPUT_HANDLE
            if WIN32COLORS.include? color
                if WIN32COLORS.index(color) >= WIN32_FOREGROUND_COLOR_MOD.length
                    the_color_mod = WIN32_FOREGROUND_COLOR_MOD[WIN32COLORS.index(color) % WIN32_FOREGROUND_COLOR_MOD.length] | FOREGROUND_INTENSITY
                else
                    the_color_mod = WIN32_FOREGROUND_COLOR_MOD[WIN32COLORS.index(color)]
                end
                Win32Kernel32.setConsoleTextAttribute the_out_handle, 0x00ff & the_color_mod
                print "#{message}\n"
                Win32Kernel32.setConsoleTextAttribute the_out_handle, 0x00ff & (FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED)
            else
                print "#{message}\n"
            end
        end

        def my_puts(message, color = nil)
            if windows?
                win32_puts_color message, color
            else
                linux_puts_color message, color
            end
        end


        def initialize(attrs = {})
            #puts "=> init logger with: #{attrs.inspect}"
            @stdout = (attrs[:stdout] == 1)
            @name = attrs[:name]
            @filename = attrs[:file].gsub(/\.log/,".#{Process.pid}.log")
            FileUtils.mkdir_p(File.dirname(@filename))
            @roll_type = attrs[:roll_type]
            @roll_param = attrs[:roll_param]
            @log_cache = attrs[:log_cache].blank? ? 1 : attrs[:log_cache].to_i
            @max_log_cnt = attrs[:max_log_cnt].blank? ? 10 : attrs[:max_log_cnt].to_i
            @cache_msg = {}
            @cache_count = 0
            @caller = attrs[:caller] || 1
            if @roll_type == "file_size" && @roll_param && (@roll_param = @roll_param.to_s)
                size = nil
                if @roll_param.index("K")
                    size = @roll_param.to_i * 1024
                elsif @roll_param.index("M")
                    size = @roll_param.to_i * 1024 * 1024
                end
                @roll_param = size
            end
            @level = LEVELS.index(attrs[:level].upcase) || 1
            @last_log_time = nil
            clean_log @filename
            @file = File.open(@filename, "a+") if @filename
            # clean_log
        end


        def self.loggers
            return LOGGERS
        end

        def self.add_log(logger)
            LOGGERS << logger
        end

        def self.get(name)
            LOGGERS.each do |__log__|
                if __log__.name == name
                    return __log__
                end
            end
        end

        attr_writer :caller

        def rename_and_create_new(newfilename)
            # fix Error::EACCESS exception throw when file is opened before rename by lyf
            begin
                @file.flush
                @file.close
                FileUtils.cp(@file.path, newfilename)
                clean_log @file.path
                @file.reopen(@file.path, "w")
            rescue Exception => e
                puts "error when try to  rename_and_create_new #{newfilename}"
            end
            #unless (FileUtils.cp(@file.path, newfilename) and FileUtils.rm_f(@file.path) and @file.reopen(@file.path, "w"))
            #    #puts "==> error rename #{@filename} => #{newfilename}"
            #end
        end

        def clean_log(the_path)
            log_patten = File.join(File.dirname(the_path), '*.log')
            # puts "need clean #{the_path}"
            FileUtils.rm_f(the_path)
            sort_time_files = Dir[log_patten].sort_by { |file|
                test(?M, file) if File.exists?(file)
            }
            # puts "sort_time_files #{sort_time_files}"
            if @max_log_cnt && @max_log_cnt > 0 && sort_time_files.length > @max_log_cnt
                (sort_time_files.length - @max_log_cnt).times do |cnt|
                    puts "need to del #{sort_time_files[cnt]} cnt #{cnt}"
                    FileUtils.rm_f sort_time_files[cnt] if File.exists?(sort_time_files[cnt])
                end
            end
        end

        def check_split_file
            begin
                if @roll_type == "daily"
                    if @last_log_time && @last_log_time.day != Time.now.day
                        p = @file.path
                        new_name = nil
                        if p.rindex(".") > p.rindex("/")
                            new_name = "#{p[0, p.rindex(".")]}.#{@last_log_time.strftime("%Y-%m-%d")}#{p[p.rindex("."), p.length]}"
                        else
                            new_name = "#{p}.#{@last_log_time.strftime("%Y-%m-%d")}"
                        end
                        rename_and_create_new(new_name)
                    end
                elsif @roll_type == "file_size"
                    if File.size(@file) >= @roll_param
                        p = @file.path
                        new_name = nil
                        if p.rindex(".") > p.rindex("/")
                            new_name = "#{p[0, p.rindex(".")]}.#{Time.now.strftime("%Y%m%d%H%M")}#{p[p.rindex("."), p.length]}"
                        else
                            new_name = "#{p}.#{Time.now.strftime("%Y%m%d%H%M")}"
                        end
                        rename_and_create_new(new_name)
                    end
                end
            rescue Exception => e
                puts "\n============= log error msg:#{e.message}!!! =============\n"
            end
        end

        def truncate
            @file.truncate(0)
            @file.flush
        end

        def log(_level, msg, err = nil)
            begin
                check_split_file if @file
                err_msg = nil
                line = ''
                if caller[@caller].respond_to? :include?
                    #my_puts "proj root ::#{ConfigManager.project_root}"
                    line = find_the_project_caller_line(@caller)
                else
                    line = caller[1].gsub(ConfigManager.project_root, '')
                end
                _msg = "#{_level},Thread::#{Thread.current},#{Time.now.strftime("%y-%m-%d %H:%M:%S")}\n#{line}: #{msg}"
                _msg += "\n" if msg[-1] != "\n"
                if $stdouttype == "GBK"
                    _msg = _msg.to_gbk
                end
                err_msg = "#{err.message}\n#{err.backtrace.join("\n\t")}" if err
                the_key = _level.strip
                @cache_msg[the_key] ||= ''
                @cache_msg[the_key] << _msg
                @cache_msg[the_key] << err_msg if err_msg
                if @cache_count < @log_cache.to_i
                    @cache_count += 1
                else
                    file_need_to_pus_cache = ''
                    the_msg_cache = @cache_msg
                    @cache_count = 0
                    @cache_msg = {}
                    the_msg_cache.each do |key, value|
                        my_puts value, COLORS[key] if @stdout
                        #puts "need to log with #{@file} [#{value}]"
                        file_need_to_pus_cache << value
                        #@file.dup if @file
                    end
                    if @file
                        @file.print file_need_to_pus_cache
                        @file.flush
                    end
                end
                @last_log_time = Time.now
            rescue Exception => e
                puts "\n==========log error !!! err msg is [#{e.message}][stack::#{e.backtrace.join("\n")}] you need to log is \n#{_msg}\n"
            end
        end

        def find_the_project_caller_line(the_caller)
            line = ''
            the_caller += 1
            loop do
                if caller[the_caller].respond_to? :include?
                    #my_puts "caller::#{the_caller}====#{caller[the_caller]}"
                    if caller[the_caller].include? ConfigManager.project_root and not caller[the_caller].include? __FILE__
                        #my_puts "===get the caller ::#{the_caller} #{caller[the_caller]} "
                        line = caller[the_caller].gsub(ConfigManager.project_root, '')
                        break
                    end
                    the_caller += 1
                else
                    line = caller[3].gsub(ConfigManager.project_root, '')
                    break
                end
            end
            line
        end

        def soft(*msg)
            log('SOFT ', msg.join(','), nil) if true
            nil
        end

        def trace(msg, err = nil)
            log('TRACE ', msg, err) if @level == 0
            nil
        end

        def debug(msg, err = nil)
            log('DEBUG ', msg, err) if @level <= 1
            nil
        end

        def info(msg, err = nil)
            log('INFO  ', msg, err) if @level <= 2
            nil
        end

        def warn(msg, err = nil)
            log('WARN  ', msg, err) if @level <= 3
            nil
        end

        def error(msg, err = nil)
            log('ERROR ', msg, err) if @level <= 4
            nil
        end

        def fatal(msg, err = nil)
            log('FATAL ', msg, err)
            nil
        end

        def debug?
            @level == 1
        end

        def info?
            @level >= 2
        end

        def add(*)
        end
    end


    class SingleLogger
        class << self
            attr_accessor :logger_config, :my_logger
        end

        def self.get_conf
            the_cfg_file = File.expand_path(File.join(ConfigManager.project_root, 'config', 'logger.yml'))
            if SingleLogger.logger_config.blank?
                if File.exist?(the_cfg_file)
                    SingleLogger.logger_config = YAML.load_file(the_cfg_file)
                end
            end
            return SingleLogger.logger_config if SingleLogger.logger_config
            {}
        end

        key = get_conf['default'] || 'dev'
        log_cfg = get_conf[key] || {}
        SingleLogger.my_logger ||= MyLogger.new({ :stdout => log_cfg['stdout'] || 1, :name => key,
                                                  :file => File.join(ConfigManager.project_root, log_cfg['file'] || './log/dev.log'),
                                                  :roll_type => log_cfg['roll_type'] || 'file_size',
                                                  :roll_param => log_cfg['roll_param'] || '5M',
                                                  :max_log_cnt => log_cfg['max_log_cnt'] || 10,
                                                  :level => log_cfg['level'] || 'debug',
                                                  :log_cache => log_cfg['log_cache'] || 0,
                                                  :caller => 2 })

        def self.new(*args)
            SingleLogger.my_logger || super(*args)
        end

        def self.get_logger
            SingleLogger.my_logger || self.new()
        end

        def initialize(*args)
            SingleLogger.my_logger || super(*args)
        end


        def self.method_missing(*arg)
            SingleLogger.my_logger.send(*arg)
        end
    end
    module ToolLogger
        def log(*arg)
            SingleLogger.get_logger.log(*arg)
        end

        def trace(*arg)
            SingleLogger.get_logger.trace(*arg)
        end

        def debug(*arg)
            SingleLogger.get_logger.debug(*arg)
        end

        def info(*arg)
            SingleLogger.get_logger.info(*arg)
        end

        def warn(*arg)
            SingleLogger.get_logger.warn(*arg)
        end

        def error(*arg)
            SingleLogger.get_logger.error(*arg)
        end

        def fatal(*arg)
            SingleLogger.get_logger.fatal(*arg)
            raise arg[1]
        end

        def debug?
            SingleLogger.get_logger.debug?
        end

        def info?
            SingleLogger.get_logger.info?
        end

        module_function :log, :trace, :debug, :info, :warn, :error, :fatal, :debug?, :info?

        def self.included(base)
            base.extend self
        end

        #def method_missing(*arg)
        #    SingleLogger.get_logger.send(*arg)
        #end

        def self.method_missing(*arg)
            SingleLogger.get_logger.send(*arg)
        end
    end
end
#TestTool::ToolLogger.error("123")
