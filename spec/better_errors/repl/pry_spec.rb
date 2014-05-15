require "spec_helper"
require "pry"
require "better_errors/repl/pry"
require "better_errors/repl/shared_examples"

module BetterErrors
  module REPL
    describe Pry do
      let(:fresh_binding) {
        local_a = 123
        binding
      }

      let(:repl) { Pry.new fresh_binding }

      it "does line continuation" do
        output, prompt, filled = repl.send_input ""
        expect(output).to eq("=> nil\n")
        expect(prompt).to eq(">>")
        expect(filled).to eq("")

        output, prompt, filled = repl.send_input "def f(x)"
        expect(output).to eq("")
        expect(prompt).to eq("..")
        expect(filled).to eq("  ")

        output, prompt, filled = repl.send_input "end"
        if RUBY_VERSION >= "2.1.0"
          expect(output).to eq("=> :f\n")
        else
          expect(output).to eq("=> nil\n")
        end
        expect(prompt).to eq(">>")
        expect(filled).to eq("")
      end

      it_behaves_like "a REPL provider"
    end
  end
end
