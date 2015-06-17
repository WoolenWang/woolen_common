# -*- encoding : utf-8 -*-
require "#{File.join(File.dirname(__FILE__), 'abstract_middleware','builder')}"
require "#{File.join(File.dirname(__FILE__), 'abstract_middleware','runner')}"
require "#{File.join(File.dirname(__FILE__), 'logger')}"
module WoolenCommon
    #  根据某个目录下的源程序，生成中间件调用队列
    class VerCtrlMiddleWare
        include WoolenCommon::ToolLogger
        attr_accessor :ver_match_hash
        def initialize(class_file_dir,&ver_ctrl_block)
            debug "init the AbstractMiddleWare with class dir ::#{class_file_dir}"
            @ver_match_hash = {}
            if File.directory? class_file_dir
                @class_dir = Dir.new(class_file_dir)
            else
                fatal "目录:#{class_file_dir}不存在,无法从中加载相关中间件代码"
            end
            @class_dir.each do |one_file|
                file_str = File.join(File.realdirpath(@class_dir),one_file)
                if File.directory? file_str
                    trace "file_str :#{file_str} 是个目录"
                    next
                end
                # 只加载ruby源程序
                if File.extname(file_str) == '.rb' || File.extname(file_str) == '.ruby'
                    base_file_name = File.basename(file_str,(File.extname(file_str)))
                    class_name = base_file_name.split('_').map!{|k| k.capitalize}.join ''
                    trace "加载文件:#{file_str},获得的类名是:#{class_name}"
                    File.open(file_str,'r') do |file|
                        self.instance_eval file.read,file_str
                    end
                    #self.instance_eval "load '#{file_str}',true;"
                    k_class = self.instance_eval class_name
                    if block_given?
                        int_ver = ver_ctrl_block.call k_class::VERSION
                    else
                        int_ver = k_class::VERSION.to_i
                    end
                    trace "file:#{file_str},version:#{k_class::VERSION},int_version:#{int_ver}"
                    if @ver_match_hash[int_ver]
                        warn "int_version :#{int_ver} 已经有类了：#{@ver_match_hash[int_ver]},略过当前类的加入：#{k_class}"
                        next
                    else
                        @ver_match_hash[int_ver] = k_class
                    end
                else
                    warn "目录:#{@class_dir.to_s}下的文件:#{file_str}不是ruby代码"
                end
            end
            trace "获取到的hash sort后是：#{@ver_match_hash.sort}"
        end

        def add_ver_class(int_ver,k_class,force=false)
            if int_ver.is_a? Integer
                if @ver_match_hash[int_ver]
                    warn "尝试添加一个ver:#{int_ver}已经存在的k_clas:#{@ver_match_hash[int_ver]},尝试添加的class:#{k_class}"
                    if force
                        info "需要强制添加类:#{k_class}"
                        @ver_match_hash[int_ver] = k_class
                    end
                else
                    @ver_match_hash[int_ver] = k_class
                end
            else
                warn "ver 不是integen：#{int_ver},要添加的class:#{k_class}"
            end
        end

        def del_ver_class_by_ver(int_ver)
            if int_ver.is_a? Integer
                if @ver_match_hash[int_ver]
                    debug "删除一个ver:#{int_ver}"
                    @ver_match_hash.delete int_ver
                else
                    debug "ver :#{int_ver} 不存在"
                end
            else
                warn "ver不是integen：#{int_ver}"
            end
        end

        def call(*args,&block)
            middle_ware_stack = Middleware::Builder.new
            sort_middle_ware_array = @ver_match_hash.sort
            sort_middle_ware_array.reverse.each do |int_ver,k_class|
                trace "添加ver:#{int_ver} 的class:#{k_class}"
                middle_ware_stack.use k_class,*args,&block
            end
            middle_ware_stack.call binding
        end
    end
end
