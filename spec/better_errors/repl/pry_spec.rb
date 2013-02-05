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

      it_behaves_like "a good repl should"

      it "should do line continuation" do
        output, prompt = repl.send_input ""
        output.should == "=> nil\n"
        prompt.should == ">>"

        output, prompt = repl.send_input "def f(x)"
        output.should == ""
        prompt.should == ".."

        output, prompt = repl.send_input "end"
        output.should == "=> nil\n"
        prompt.should == ">>"
      end
    end
  end
end
