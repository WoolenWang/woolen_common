# -*- encoding : utf-8 -*-
require 'singleton'
require "#{File.join(File.dirname(__FILE__), 'actionpool')}"
require "#{File.join(File.dirname(__FILE__), 'logger')}"
module WoolenCommon
    class ActionPoolProxy < BasicObject
        MAX_THREAD = 10

        class << self
            include WoolenCommon::ToolLogger
            def get_pool
                @action_pool ||= ::ActionPool::Pool.new(:min_thread => 1, :max_thread => MAX_THREAD)
            end

            def process(*args,&block)
                trace "invoke the action pool process,args:#{args}"
                begin
                    self.get_pool.process(*args,&block)
                rescue Exception => e
                    error "we get the invoke process error::#{e.message}",e
                end
            end
        end
    end
end
