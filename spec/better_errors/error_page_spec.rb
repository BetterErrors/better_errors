require "spec_helper"

module BetterErrors
  describe ErrorPage do
    let(:exception) { raise ZeroDivisionError, "you divided by zero you silly goose!" rescue $! }
  
    let(:error_page) { ErrorPage.new exception, { "REQUEST_PATH" => "/some/path" } }
    
    let(:response) { error_page.render }
  
    it "should include the error message" do
      response.should include("you divided by zero you silly goose!")
    end
  
    it "should include the request path" do
      response.should include("/some/path")
    end
  
    it "should include the exception class" do
      response.should include("ZeroDivisionError")
    end
    
    context "when showing source code" do
      before do
        exception.stub!(:backtrace).and_return([
          "#{File.expand_path("../support/my_source.rb", __FILE__)}:8:in `some_method'"
        ])
      end
      
      it "should show the line where the exception was raised" do
        response.should include("8 eight")
      end
      
      it "should show five lines of context" do
        response.should include("3 three")
        response.should include("13 thirteen")
      end
      
      it "should not show more than five lines of context" do
        response.should_not include("2 two")
        response.should_not include("14 fourteen")
      end
    end
  end
end
