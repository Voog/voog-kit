# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'edicy/dtk/version'

Gem::Specification.new do |spec|
  spec.name          = 'edicy-dtk'
  spec.version       = Edicy::Dtk::VERSION
  spec.authors       = ['Mikk Pristavka', 'Priit Haamer']
  spec.email         = ['mikk@fraktal.ee', 'priit@edicy.com']
  spec.description   = %q{Tools that help Edicy design development}
  spec.summary       = %q{Edicy Designer Toolkit}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.bindir        = 'bin'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  
  spec.add_runtime_dependency 'gli'
  spec.add_runtime_dependency 'git'
  spec.add_runtime_dependency 'parseconfig'
  spec.add_runtime_dependency 'edicy_api'
  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency 'mime-types'
end
