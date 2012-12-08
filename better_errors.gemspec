# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'better_errors/version'

Gem::Specification.new do |s|
  s.name          = "better_errors"
  s.version       = BetterErrors::VERSION
  s.authors       = ["Charlie Somerville"]
  s.email         = ["charlie@charliesomerville.com"]
  s.description   = %q{Better Errors gives Rails a better error page.}
  s.summary       = %q{Better Errors gives Rails a better error page}
  s.homepage      = "https://github.com/charliesome/better_errors"
  s.license       = "MIT"

  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  
  s.add_dependency "erubis"
  s.add_dependency "coderay"
  
  # optional dependency:
  # s.add_dependency "binding_of_caller"
end
