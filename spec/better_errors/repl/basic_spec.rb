require "spec_helper"
require "better_errors/repl/basic"
require "better_errors/repl/shared_examples"

module BetterErrors
  module REPL
    describe Basic do
      let(:fresh_binding) {
        local_a = 123
        binding
      }
      
      let(:repl) { Basic.new fresh_binding }

      include_examples "repl shared examples"
    end
  end
end
