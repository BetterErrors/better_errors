require 'rubygems'
require 'rubygems/command.rb'
require 'rubygems/dependency_installer.rb' 

begin
  Gem::Command.build_args = ARGV
rescue NoMethodError
end 

gem = Gem::DependencyInstaller.new

begin
  if ["rbx", "ruby"].include?(RUBY_ENGINE)
    gem.install "binding_of_caller", "0.7.2"
  end
rescue
  exit(1)
end 
