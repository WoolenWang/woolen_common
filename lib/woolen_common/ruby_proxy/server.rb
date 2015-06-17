# -*- encoding : utf-8 -*-
require 'rubygems'
require 'drb'
require "#{File.join(File.dirname(__FILE__), 'config')}"
require "#{File.join(File.dirname(__FILE__), 'proxy')}"
require 'drb/timeridconv'
module RubyProxy
    class DRbServer
        include WoolenCommon::ToolLogger
        @ip = Config.ip
        @port = Config.port

        class << self
            attr_accessor :ip, :port
        end

        def self.start_service
            DRb.install_id_conv(DRb::TimerIdConv.new)
            DRb.start_service("druby://#{ip}:#{port}", Proxy)
            #~ trap("INT") { DRb.stop_service }
            # for ruby1.9
            begin
                Proxy.worker_start
                DRb.thread.join
            rescue Exception => e
                error "服务线程异常:#{e.message}",e
            ensure
                DRb.stop_service
            end
        end

        def self.stop_service
            DRb.stop_service
        end
    end
end

if $0 == __FILE__
    #~ ['INT'].each do |signal|
    #~ trap(signal) {
    #~ puts 'exit...'
    #~ RubyProxy::DRbServer.stop_service
    #~ }
    #~ end
    #~ puts "start server ip:#{ARGV[0] || "127.0.0.1"}"
    #~ puts "start server port:#{ARGV[1] || 9000}"
    RubyProxy::DRbServer.ip = ARGV[0] unless ARGV[0].nil?
    RubyProxy::DRbServer.port = ARGV[1] unless ARGV[1].nil?
    puts "start server ip: #{RubyProxy::DRbServer.ip}"
    puts "start server port:#{RubyProxy::DRbServer.port}"
    #~ Dir.chdir ARGV[2] unless ARGV[2].nil?
    RubyProxy::DRbServer.start_service
end
