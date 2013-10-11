# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dnsserver/version'

Gem::Specification.new do |spec|
  spec.name          = "dnsserver"
  spec.version       = DNSServer::VERSION
  spec.authors       = ["Keith Larrimore"]
  spec.email         = ["keithlarrimore@gmail.com"]
  spec.description   = ""
  spec.summary       = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency 'awesome_print', '~> 1.1.0'
  spec.add_runtime_dependency 'slop', '~> 3.4.6'
  spec.add_runtime_dependency 'settingslogic', '~> 2.0.8'
  spec.add_runtime_dependency 'hashie', '~> 2.0.2'
  spec.add_runtime_dependency 'rubydns', '~> 0.6.6'
  spec.add_runtime_dependency 'dante', '~> 0.1.5'
  spec.add_runtime_dependency 'pry', '~> 0.9.10'
  spec.add_runtime_dependency 'god', '~> 0.13.3'
  spec.add_runtime_dependency 'dante', '~> 0.1.5'
end
