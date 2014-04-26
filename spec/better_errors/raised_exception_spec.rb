require "spec_helper"

module BetterErrors
  describe RaisedException do
    let(:exception) { RuntimeError.new("whoops") }
    subject { RaisedException.new(exception) }

    its(:exception) { should == exception }
    its(:message)   { should == "whoops" }
    its(:type)      { should == RuntimeError }

    it { should_not be_syntax_error }

    context "when the exception wraps another exception" do
      let(:original_exception) { RuntimeError.new("something went wrong!") }
      let(:exception) { double(:original_exception => original_exception) }

      its(:exception) { should == original_exception }
      its(:message)   { should == "something went wrong!" }
    end

    context "when the exception is a syntax error" do
      let(:exception) { SyntaxError.new("foo.rb:123: you made a typo!") }

      its(:message) { should == "you made a typo!" }
      its(:type)    { should == SyntaxError }

      it { should be_syntax_error }
    end
  end
end
