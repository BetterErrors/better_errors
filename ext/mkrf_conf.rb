require 'rubygems/dependency_installer'

gem = Gem::DependencyInstaller.new

if ["rbx", "ruby"].include?(RUBY_ENGINE)
  # This MUST match the version specified in lib/better_errors.rb, or else
  # weird shit will happen.
  if Gem::Dependency.new("binding_of_caller", "0.7.2").matching_specs.empty?
    gem.install "binding_of_caller", "0.7.2"
  end
end
