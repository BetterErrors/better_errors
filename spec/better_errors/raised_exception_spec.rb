require "spec_helper"

module BetterErrors
  describe RaisedException do
    let(:exception) { RuntimeError.new("whoops") }
    subject { RaisedException.new(exception) }

    its(:exception) { should == exception }
    its(:message)   { should == "whoops" }
    its(:type)      { should == RuntimeError }

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

      it "has the right filename and line number in the backtrace" do
        subject.backtrace.first.filename.should == "foo.rb"
        subject.backtrace.first.line.should == 123
      end
    end

    context "when the exception is a HAML syntax error" do
      before do
        stub_const("Haml::SyntaxError", Class.new(SyntaxError))
      end

      let(:exception) {
        Haml::SyntaxError.new("you made a typo!").tap do |ex|
          ex.set_backtrace(["foo.rb:123", "haml/internals/blah.rb:123456"])
        end
      }

      its(:message) { should == "you made a typo!" }
      its(:type)    { should == Haml::SyntaxError }

      it "has the right filename and line number in the backtrace" do
        subject.backtrace.first.filename.should == "foo.rb"
        subject.backtrace.first.line.should == 123
      end
    end

    context "when the exception is a Coffeelint syntax error" do
      before do
        stub_const("Sprockets::Coffeelint::Error", Class.new(SyntaxError))
      end

      let(:exception) {
        Sprockets::Coffeelint::Error.new("[stdin]:11:88: error: unexpected=").tap do |ex|
          ex.set_backtrace(["app/assets/javascripts/files/index.coffee:11", "sprockets/coffeelint.rb:3"])
        end
      }

      its(:message) { should == "[stdin]:11:88: error: unexpected=" }
      its(:type)    { should == Sprockets::Coffeelint::Error }

      it "has the right filename and line number in the backtrace" do
        subject.backtrace.first.filename.should == "app/assets/javascripts/files/index.coffee"
        subject.backtrace.first.line.should == 11
      end
    end
  end
end
