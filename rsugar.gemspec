# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rsugar/version'

Gem::Specification.new do |spec|
  spec.name          = "rsugar"
  spec.version       = Rsugar::VERSION
  spec.authors       = ["Justin Wiley"]
  spec.email         = ["justin.wiley@gmail.com"]
  spec.description   = %q{RSugar allows you to execute R language commands from Ruby.  It wraps rserve_client gem, providing some syntactic sugar and a few helper methods.}
  spec.summary       = %q{RSugar allows you to execute R language commands from Ruby.  It wraps rserve_client gem, providing some syntactic sugar and a few helper methods.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rserve-client"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
