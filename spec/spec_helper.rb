$: << File.expand_path("../../lib", __FILE__)

ENV["EDITOR"] = nil

require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = 'coverage/lcov.info'
end
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter,
  ]
)
SimpleCov.start do
  add_filter 'spec/'
end

require 'bundler/setup'
Bundler.require(:default)

require 'rspec-html-matchers'

RSpec.configure do |config|
  config.include RSpecHtmlMatchers
end
