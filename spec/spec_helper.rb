$: << File.expand_path("../../lib", __FILE__)

ENV["EDITOR"] = nil

require 'coveralls'
Coveralls.wear! do
  add_filter 'spec/'
end

require 'bundler/setup'
Bundler.require(:default)
