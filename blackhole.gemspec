# coding: utf-8
# lib = File.expand_path('../lib', __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# get the blockhole version
require './lib/blackhole/version'

Gem::Specification.new do |spec|
  spec.name          = "blackhole"
  spec.version       = Blackhole::VERSION
  spec.authors       = ["Maarten van Gijssel"]
  spec.email         = ["maarten@vgijssel.nl"]
  spec.description   = %q{Creates a BlackHole object which can nest indefinite amount of properties.}
  spec.summary       = %q{Gem for parameter like access to a hash.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
