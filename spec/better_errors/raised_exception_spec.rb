require "spec_helper"

module BetterErrors
  describe RaisedException do
    let(:exception) { RuntimeError.new("whoops") }
    subject { RaisedException.new(exception) }

    describe '#exception' do
      subject { super().exception }
      it { should == exception }
    end

    describe '#message' do
      subject { super().message }
      it   { should == "whoops" }
    end

    describe '#type' do
      subject { super().type }
      it      { should == RuntimeError }
    end

    context "when the exception wraps another exception" do
      let(:original_exception) { RuntimeError.new("something went wrong!") }
      let(:exception) { double(:original_exception => original_exception) }

      describe '#exception' do
        subject { super().exception }
        it { should == original_exception }
      end

      describe '#message' do
        subject { super().message }
        it   { should == "something went wrong!" }
      end
    end

    context "when the exception is a syntax error" do
      let(:exception) { SyntaxError.new("foo.rb:123: you made a typo!") }

      describe '#message' do
        subject { super().message }
        it { should == "you made a typo!" }
      end

      describe '#type' do
        subject { super().type }
        it    { should == SyntaxError }
      end

      it "has the right filename and line number in the backtrace" do
        expect(subject.backtrace.first.filename).to eq("foo.rb")
        expect(subject.backtrace.first.line).to eq(123)
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

      describe '#message' do
        subject { super().message }
        it { should == "you made a typo!" }
      end

      describe '#type' do
        subject { super().type }
        it    { should == Haml::SyntaxError }
      end

      it "has the right filename and line number in the backtrace" do
        expect(subject.backtrace.first.filename).to eq("foo.rb")
        expect(subject.backtrace.first.line).to eq(123)
      end
    end
  end
end
