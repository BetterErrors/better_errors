require "spec_helper"
require "better_errors/repl/basic"

module BetterErrors
  module REPL
    describe Basic do
      let(:fresh_binding) {
        local_a = 123
        binding
      }
      
      let(:repl) { Basic.new fresh_binding }
      
      it "should evaluate ruby code in a given context" do
        repl.send_input("local_a = 456")
        expect(fresh_binding.eval("local_a")).to eq(456)
      end
      
      it "should return a tuple of output and the new prompt" do
        output, prompt = repl.send_input("1 + 2")
        expect(output).to eq("=> 3\n")
        expect(prompt).to eq(">>")
      end
      
      it "should not barf if the code throws an exception" do
        output, prompt = repl.send_input("raise Exception")
        expect(output).to eq("!! #<Exception: Exception>\n")
        expect(prompt).to eq(">>")
      end
    end
  end
end
