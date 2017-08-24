require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)
task :default => :test

def gemfiles
  @gemfiles ||= Dir[File.dirname(__FILE__) + '/gemfiles/*.gemfile']
end

def with_each_gemfile
  gemfiles.each do |gemfile|
    Bundler.with_clean_env do
      puts "\n=========== Using gemfile: #{gemfile}"
      ENV['BUNDLE_GEMFILE'] = gemfile
      yield
    end
  end
end

namespace :test do
  namespace :bundles do
    desc "Install all dependencies necessary to test"
    task :install do
      with_each_gemfile { sh "bundle install" }
    end

    desc "Update all dependencies for tests"
    task :update do
      with_each_gemfile { sh "bundle update" }
    end
  end

  desc "Test all supported sets of dependencies."
  task :all => 'test:bundles:install' do
    with_each_gemfile { sh "bundle exec rspec" rescue nil }
  end
end
