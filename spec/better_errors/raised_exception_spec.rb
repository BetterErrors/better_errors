require "spec_helper"

module BetterErrors
  describe RaisedException do
    context "#exception" do
      let(:exception) { RuntimeError.new("whoops") }

      it "returns the wrapped exception" do
        RaisedException.new(exception).exception.should == exception
      end

      it "returns the original exception, if there is one" do
        wrapper = double(:original_exception => exception)
        RaisedException.new(wrapper).exception.should == exception
      end
    end
  end
end
