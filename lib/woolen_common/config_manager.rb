# -*- encoding : utf-8 -*-
require 'yaml'
module WoolenCommon
    class ConfigManager
        class << self
            attr_accessor :project_root

=begin
	功能: 获取配置
	描述:
	      先设置好项目的根目录,如D:/ACAT3.1
		  返回为YAML对象的D:/ATCAT3.1/config/xx.yml
	参数: name 配置文件的名字
	返回值:
		  YAML对象
	       未设置root,抛出RuntimeErorr
		   配置不存在,抛出RuntimeErorr
	举例:
		  ConfigureManager.root = $root
		  puts ConfigureManager.get("test")['test']
=end
            def get(name)
                name += ".yml" unless name.match(/.yml$/)
                name = name
                raise "not set root path, please use ConfigureManager.root=() to set it" if project_root.nil?
                path = File.join(project_root, "config", name) #File.join(root,"config",name).to_gbk
                path = File.expand_path(path)
                #~ path = Pathname.new(path).realpath
                raise "The special config path #{path} not exist" unless File.exist?(path)
                #  because empty file when get 'false' so we add {} return value.
                YAML.load_file(path) || {}
            end
        end
    end
end
# WoolenCommon::ConfigManager.project_root = File.expand_path(File.join(File.dirname(__FILE__),'..','..','..'))
