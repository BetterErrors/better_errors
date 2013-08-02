require "simplecov"
SimpleCov.start

$: << File.expand_path("../../lib", __FILE__)
ENV["EDITOR"] = nil
require "better_errors"
require "ostruct"
