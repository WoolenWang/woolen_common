ENV['RUBYTAOBAO'] = 'true'
if ENV['RUBYTAOBAO']
    source 'https://ruby.taobao.org'
else
    source 'https://rubygems.org'
end
# Specify your gem's dependencies in woolen_common.gemspec

gem 'ffi'
puts "version #{RUBY_VERSION}"
if RUBY_VERSION < '2.0.0'
    gem 'net-ssh', '~> 2.9'
    gem 'net-sftp', '~> 2.1'
else
    gem 'net-ssh', '>= 2.9.1'
    gem 'net-sftp', '>= 2.1.2'
end
gemspec
