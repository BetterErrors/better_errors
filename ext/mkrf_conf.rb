require 'rubygems/dependency_installer'

gem = Gem::DependencyInstaller.new

if ["rbx", "ruby"].include?(RUBY_ENGINE)
  if Gem::Dependency.new("binding_of_caller", "0.7.2").matching_specs.empty?
    gem.install "binding_of_caller", "0.7.2"
  end
end
