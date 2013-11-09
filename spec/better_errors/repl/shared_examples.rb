shared_examples_for "a REPL provider" do
  it "evaluates ruby code in a given context" do
    repl.send_input("local_a = 456")
    fresh_binding.eval("local_a").should == 456
  end
  
  it "returns a tuple of output and the new prompt" do
    output, prompt = repl.send_input("1 + 2")
    output.should == "=> 3\n"
    prompt.should == ">>"
  end
  
  it "doesn't barf if the code throws an exception" do
    output, prompt = repl.send_input("raise Exception")
    output.should include "Exception: Exception"
    prompt.should == ">>"
  end
end
