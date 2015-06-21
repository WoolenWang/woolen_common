# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'woolen_common/version'

Gem::Specification.new do |spec|
  spec.name          = 'woolen_common'
  spec.version       = WoolenCommon::VERSION
  spec.authors       = ['just_woolen']
  spec.email         = ['just_woolen@qq.com']
  spec.summary       = %q{woolen_common}
  spec.description   = %q{The common helper for dev in ruby}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'actionpool', '~> 0.2', '>= 0.2.3'
end
