# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'voog/dtk/version'

Gem::Specification.new do |spec|
  spec.name          = 'voog-kit'
  spec.version       = Voog::Dtk::VERSION
  spec.authors       = ['Mikk Pristavka', 'Priit Haamer']
  spec.email         = ['mikk@voog.com', 'priit@voog.com']
  spec.description   = %q{Tools that help Voog design development}
  spec.summary       = %q{Voog Developer Toolkit}
  spec.homepage      = 'http://voog.com/developers/kit'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.bindir        = 'bin'

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'guard-rspec'
  
  spec.add_runtime_dependency 'gli', '2.10.0'
  spec.add_runtime_dependency 'pry', '>= 0.9.12'
  spec.add_runtime_dependency 'guard', '>= 2.3.0', '< 3.0'
  spec.add_runtime_dependency 'git'
  spec.add_runtime_dependency 'parseconfig'
  spec.add_runtime_dependency 'voog_api', '~> 0.0.7'
  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency 'mime-types', '>= 1.25.1', '< 3.0'
  spec.add_runtime_dependency 'rb-readline'
end
