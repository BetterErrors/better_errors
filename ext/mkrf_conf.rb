require 'rubygems/dependency_installer' 

gem = Gem::DependencyInstaller.new

if ["rbx", "ruby"].include?(RUBY_ENGINE)
  gem.install "binding_of_caller", "0.7.2"
end
