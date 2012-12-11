require "spec_helper"

module BetterErrors
  describe System do
    it "should have Sublime method" do
      BetterErrors::System.should respond_to(:sublime_available?)
    end
  end
end

