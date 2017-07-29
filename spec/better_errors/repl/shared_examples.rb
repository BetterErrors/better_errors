shared_examples_for "a REPL provider" do
  it "evaluates ruby code in a given context" do
    repl.send_input("local_a = 456")
    expect(fresh_binding.eval("local_a")).to eq(456)
  end

  it "returns a tuple of output and the new prompt" do
    output, prompt = repl.send_input("1 + 2")
    expect(output).to eq("=> 3\n")
    expect(prompt).to eq(">>")
  end

  it "doesn't barf if the code throws an exception" do
    output, prompt = repl.send_input("raise Exception")
    expect(output).to include "Exception: Exception"
    expect(prompt).to eq(">>")
  end
end
