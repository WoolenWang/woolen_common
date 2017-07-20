ENV['USE_INTERNET_SOURCE'] = 'true'
#sangfor source
if File.exist? File.join(File.dirname(__FILE__),'.ruby_env.rb')
    require File.join(File.dirname(__FILE__),'.ruby_env.rb')
end
if ENV['USE_INTERNET_SOURCE']
    source 'http://gems.ruby-china.org'
else
    source 'http://200.200.0.35'
    source 'http://200.200.0.34:4000'
end
# Specify your gem's dependencies in woolen_common.gemspec

gem 'ffi'
gem 'connection_pool'
puts "version #{RUBY_VERSION}"
if RUBY_VERSION < '2.0.0'
    gem 'net-ssh', '~> 2.9'
    gem 'net-sftp', '~> 2.1'
else
    gem 'net-ssh', '>= 2.9.1'
    gem 'net-sftp', '>= 2.1.2'
end
gemspec
