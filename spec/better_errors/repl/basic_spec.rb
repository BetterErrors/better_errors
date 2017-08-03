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

      let!(:exception) { raise ZeroDivisionError, "you divided by zero you silly goose!" rescue $! }

      let(:repl) { Basic.new(fresh_binding, exception) }

      it_behaves_like "a REPL provider"
    end
  end
end
