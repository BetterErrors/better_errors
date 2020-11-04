require "spec_helper"
require "rspec/its"

module BetterErrors
  describe RaisedException do
    let(:exception) { RuntimeError.new("whoops") }
    subject(:described_instance) { RaisedException.new(exception) }

    before do
      allow(BetterErrors::ExceptionHint).to receive(:new).and_return(exception_hint)
    end
    let(:exception_hint) { instance_double(BetterErrors::ExceptionHint, hint: nil) }

    its(:exception) { is_expected.to eq exception }
    its(:message)   { is_expected.to eq "whoops" }
    its(:type)      { is_expected.to eq RuntimeError }

    context 'when the exception is an ActionView::Template::Error that responds to #cause (Rails 6+)' do
      before do
        stub_const(
          "ActionView::Template::Error",
          Class.new(StandardError) do
            def cause
              RuntimeError.new("something went wrong!")
            end
          end
        )
      end
      let(:exception) {
        ActionView::Template::Error.new("undefined method `something!' for #<Class:0x00deadbeef>")
      }

      its(:message) { is_expected.to eq "something went wrong!" }
      its(:type) { is_expected.to eq RuntimeError }
    end

    context 'when the exception is a Rails < 6 exception that has an #original_exception' do
      let(:original_exception) { RuntimeError.new("something went wrong!") }
      let(:exception) { double(:original_exception => original_exception) }

      its(:exception) { is_expected.to eq original_exception }
      its(:message) { is_expected.to eq "something went wrong!" }
      its(:type) { is_expected.to eq RuntimeError }
    end

    context "when the exception is a SyntaxError" do
      let(:exception) { SyntaxError.new("foo.rb:123: you made a typo!") }

      its(:message) { is_expected.to eq "you made a typo!" }
      its(:type)    { is_expected.to eq SyntaxError }

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

      its(:message) { is_expected.to eq "you made a typo!" }
      its(:type)    { is_expected.to eq Haml::SyntaxError }

      it "has the right filename and line number in the backtrace" do
        expect(subject.backtrace.first.filename).to eq("foo.rb")
        expect(subject.backtrace.first.line).to eq(123)
      end
    end

    # context "when the exception is an ActionView::Template::Error" do
    #
    #   let(:exception) {
    #     ActionView::Template::Error.new("undefined method `something!' for #<Class:0x00deadbeef>")
    #   }
    #
    #   its(:message) { is_expected.to eq "undefined method `something!' for #<Class:0x00deadbeef>" }
    #
    #   it "has the right filename and line number in the backtrace" do
    #     expect(subject.backtrace.first.filename).to eq("app/views/foo/bar.haml")
    #     expect(subject.backtrace.first.line).to eq(42)
    #   end
    # end
    #
    context "when the exception is a Coffeelint syntax error" do
      before do
        stub_const("Sprockets::Coffeelint::Error", Class.new(SyntaxError))
      end

      let(:exception) {
        Sprockets::Coffeelint::Error.new("[stdin]:11:88: error: unexpected=").tap do |ex|
          ex.set_backtrace(["app/assets/javascripts/files/index.coffee:11", "sprockets/coffeelint.rb:3"])
        end
      }

      its(:message) { is_expected.to eq "[stdin]:11:88: error: unexpected=" }
      its(:type)    { is_expected.to eq Sprockets::Coffeelint::Error }

      it "has the right filename and line number in the backtrace" do
        expect(subject.backtrace.first.filename).to eq("app/assets/javascripts/files/index.coffee")
        expect(subject.backtrace.first.line).to eq(11)
      end
    end

    describe '#hint' do
      subject(:hint) { described_instance.hint }

      it 'uses ExceptionHint to get a hint for the exception' do
        hint
        expect(BetterErrors::ExceptionHint).to have_received(:new).with(exception)
      end

      context "when ExceptionHint returns a string" do
        let(:exception_hint) { instance_double(BetterErrors::ExceptionHint, hint: "Hint text") }

        it 'returns the value from ExceptionHint' do
          expect(hint).to eq("Hint text")
        end
      end
    end
  end
end
