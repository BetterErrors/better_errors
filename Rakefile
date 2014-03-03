require "bundler/gem_tasks"
require "rspec/core/rake_task"

namespace :test do
  RSpec::Core::RakeTask.new(:with_binding_of_caller)

  without_task = RSpec::Core::RakeTask.new(:without_binding_of_caller)
  without_task.ruby_opts = "-I spec -r without_binding_of_caller"

  task :all => [:with_binding_of_caller, :without_binding_of_caller]
end

task :default => "test:all"
