# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blaster/version'

Gem::Specification.new do |spec|
  spec.name          = 'blaster'
  spec.version       = Blaster::VERSION
  spec.authors       = ['Kaz Walker']
  spec.email         = ['kaz.walker@doopli.co']
  spec.description   = %q{A gem to control USB dart guns.}
  spec.summary       = %q{A gem to control USB dart guns.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_dependency 'libusb'
end
