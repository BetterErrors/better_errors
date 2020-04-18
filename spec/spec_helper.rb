$: << File.expand_path("../../lib", __FILE__)

ENV["EDITOR"] = nil

# Ruby 2.4.0 and 2.4.1 has a bug with its Coverage module that causes segfaults.
# https://bugs.ruby-lang.org/issues/13305
# 2.4.2 should include this patch.
if ENV['CI']
  unless RUBY_VERSION == '2.4.0' || RUBY_VERSION == '2.4.1'
    require 'coveralls'
    Coveralls.wear! do
      add_filter 'spec/'
    end
  end
else
  require 'simplecov'
  SimpleCov.start
end

require 'bundler/setup'
Bundler.require(:default)

require 'rspec-html-matchers'

RSpec.configure do |config|
  config.include RSpecHtmlMatchers
end
