# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "puppet-runner"
  spec.version       = "0.0.8"
  spec.authors       = ["Martin Brehovsky"]
  spec.email         = ["mbrehovsky@adaptavist.com"]
  spec.summary       = %q{Preprocessor for hiera config}
  spec.description   = %q{Loads user config and created result hiera config and executes puppet apply with it.}
  spec.homepage      = "http://www.adaptavist.com"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = ["puppet-runner"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_dependency "docopt", ">= 0.5.0"
  spec.add_dependency "colorize", ">= 0.7.3"
  spec.add_dependency 'deep_merge'
  spec.add_dependency 'facter'
end

