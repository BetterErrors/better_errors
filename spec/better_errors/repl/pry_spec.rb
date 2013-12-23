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
        output.should == "=> nil\n"
        prompt.should == ">>"
        filled.should == ""

        output, prompt, filled = repl.send_input "def f(x)"
        output.should == ""
        prompt.should == ".."
        filled.should == "  "

        output, prompt, filled = repl.send_input "end"
        if RUBY_VERSION >= "2.1.0"
          output.should == "=> :f\n"
        else
          output.should == "=> nil\n"
        end
        prompt.should == ">>"
        filled.should == ""
      end

      it_behaves_like "a REPL provider"
    end
  end
end
