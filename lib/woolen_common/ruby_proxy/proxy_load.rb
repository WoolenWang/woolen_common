# -*- encoding : utf-8 -*-
module RubyProxy
    class ProxyLoad
        include WoolenCommon::ToolLogger

        @load_path = []
        class <<self
            attr_accessor :load_path

            def load
                load_path.uniq.each do |p|
                    if File.directory?(p)
                        Dir[p.chomp("/") + "/*.rb"].each do |file|
                            load_file(file)
                        end
                    else
                        load_file(p)
                    end
                end
            end

            def load_file(file)
                begin
                    trace "require file : #{file}"
                    require file
                    trace "finish require file : #{file}"
                rescue Exception => e
                    warn "require file : #{file} fail,exception:\n#{e}", e
                    raise e
                end
            end
        end
    end
end
