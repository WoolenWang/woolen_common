# -*- encoding : utf-8 -*-
require "#{File.join(File.dirname(__FILE__),'..', 'logger')}"
module WoolenCommon
    module Middleware
        class MapCfgManager
            include WoolenCommon::ToolLogger
            MERGE_TYPE_REPLACE = 'replace'
            MERGE_TYPE_HASH = 'hash'
            MERGE_TYPE_ARRAY = 'array'
            attr_accessor :cfg_hash,:merge_type
            def initialize(cfg_path,cfg_type='yml',merge_type = MERGE_TYPE_REPLACE)
                case cfg_type
                    when 'yml'
                        @cfg_hash = YmlCfgManager.load cfg_path
                    else
                        error "不支持的配置文件格式:#{cfg_type}"
                end
                @merge_type = merge_type
            end

            def add_cfg(cfg_path,cfg_type='yml')
                case cfg_type
                    when 'yml'
                        add_cfg = YmlCfgManager.load cfg_path
                    else
                        add_cfg = {}
                        error "不支持的配置文件格式:#{cfg_type}"
                end
                @cfg_hash.merge! add_cfg do |key,old_val,new_val|
                    case @merge_type
                        when MERGE_TYPE_REPLACE
                            ret_val = new_val
                        when MERGE_TYPE_HASH
                            ret_val = {:old_val=>old_val,:new_val=>new_val}
                        when MERGE_TYPE_ARRAY
                            ret_val = [new_val,old_val]
                        else
                            ret_val = old_val
                    end
                    trace "merge key :#{key},the old_val :#{old_val},the new_val :#{new_val},ret_val :#{ret_val}"
                    ret_val
                end
            end
        end

        class YmlCfgManager
            def self.load(path)
                YAML.load_file(path) || {}
            end
        end
    end
end
