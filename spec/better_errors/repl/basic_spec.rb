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

      it_behaves_like "a REPL provider"
    end
  end
end
