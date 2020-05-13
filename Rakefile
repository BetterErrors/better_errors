require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "sassc"

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

namespace :style do
  desc "Build main.development.css (overrides main.css)"
  task :develop => [:build] do
    root_dir = File.dirname(__FILE__)
    style_dir = "#{root_dir}/style"
    output_dir = "#{root_dir}/lib/better_errors/templates"

    engine = SassC::Engine.new(
      File.read("#{style_dir}/main.scss"),
      filename: "#{style_dir}/main.scss",
      style: :expanded,
      line_comments: true,
      load_paths: [style_dir],
    )
    css = engine.render
    File.open("#{output_dir}/main.development.css", "w") do |f|
      f.write(css)
    end
  end

  desc "Build main.css from the SASS sources"
  task :build do
    root_dir = File.dirname(__FILE__)
    style_dir = "#{root_dir}/style"
    output_dir = "#{root_dir}/lib/better_errors/templates"

    engine = SassC::Engine.new(
      File.read("#{style_dir}/main.scss"),
      filename: "#{style_dir}/main.scss",
      style: :compressed,
      load_paths: [style_dir],
    )
    css = engine.render
    File.open("#{output_dir}/main.css", "w") do |f|
      f.write(css)
    end
  end
end
