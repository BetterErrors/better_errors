# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'better_errors/version'

Gem::Specification.new do |s|
  s.name          = "better_errors"
  s.version       = BetterErrors::VERSION
  s.authors       = ["Charlie Somerville"]
  s.email         = ["charlie@charliesomerville.com"]
  s.description   = %q{Provides a better error page for Rails and other Rack apps. Includes source code inspection, a live REPL and local/instance variable inspection for all stack frames.}
  s.summary       = %q{Better error page for Rails and other Rack apps}
  s.homepage      = "https://github.com/charliesome/better_errors"
  s.license       = "MIT"

  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 1.9.2"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.12.0"
  s.add_development_dependency "binding_of_caller"
  s.add_development_dependency "pry"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "yard"
  s.add_development_dependency "redcarpet"
  
  s.add_dependency "erubis", ">= 2.6.6"
  s.add_dependency "coderay", ">= 1.0.0"

  # optional dependencies:
  # s.add_dependency "binding_of_caller"
  # s.add_dependency "pry"
end
