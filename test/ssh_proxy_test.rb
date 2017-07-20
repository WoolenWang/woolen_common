require 'test/unit'
require "#{File.expand_path File.join(File.dirname(__FILE__),'test_helper')}"
class MyTest < Test::Unit::TestCase
    include WoolenCommon::ToolLogger

    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
    end

    # Called after every test method runs. Can be used to tear
    # down fixture information.

    def teardown
        File.delete File.expand_path(File.join(File.dirname(__FILE__),'cpu_info')) rescue nil
        File.delete File.expand_path(File.join(File.dirname(__FILE__),'cpu_info_xx')) rescue nil
    end

    # Fake test
    def test_exec
        local_proxy = WoolenCommon::SshProxy.get_ssh_proxy 'localhost','22','test','test'
        assert_equal local_proxy.exec!('echo hello'),"hello\n"
        local_proxy.exec('echo hello')
        local_proxy.sftp_download!('/proc/cpuinfo',File.expand_path(File.join(File.dirname(__FILE__),'cpu_info')))
        assert_equal true,File.exists?(File.expand_path(File.join(File.dirname(__FILE__),'cpu_info')))
        local_proxy.sftp_upload!(File.expand_path(File.join(File.dirname(__FILE__),'cpu_info_xx')),File.expand_path(File.join(File.dirname(__FILE__),'cpu_info')))
        assert_equal true,File.exists?(File.expand_path(File.join(File.dirname(__FILE__),'cpu_info_xx')))
    end


    # Fake test
    def test_pool_exec
        local_proxy = WoolenCommon::SshProxyPool.get_ssh_proxy 'localhost','test','test',22
        assert_equal local_proxy.exec!('echo hello'),"hello\n"
        local_proxy.exec('echo hello')
        local_proxy.sftp_download!('/proc/cpuinfo',File.expand_path(File.join(File.dirname(__FILE__),'cpu_info')))
        assert_equal true,File.exists?(File.expand_path(File.join(File.dirname(__FILE__),'cpu_info')))
        local_proxy.sftp_upload!(File.expand_path(File.join(File.dirname(__FILE__),'cpu_info_xx')),File.expand_path(File.join(File.dirname(__FILE__),'cpu_info')))
        assert_equal true,File.exists?(File.expand_path(File.join(File.dirname(__FILE__),'cpu_info_xx')))
    end
end