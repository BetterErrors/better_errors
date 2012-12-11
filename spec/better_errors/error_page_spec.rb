require "spec_helper"

module BetterErrors
  describe ErrorPage do
    let(:exception) { raise ZeroDivisionError, "you divided by zero you silly goose!" rescue $! }
  
    let(:error_page) { ErrorPage.new exception, { "REQUEST_PATH" => "/some/path" } }
    
    let(:response) { error_page.render }
    
    let(:empty_binding) {
      local_a = :value_for_local_a
      local_b = :value_for_local_b
      
      @inst_c = :value_for_inst_c
      @inst_d = :value_for_inst_d
      
      binding
    }
  
    it "should include the error message" do
      expect(response).to include("you divided by zero you silly goose!")
    end
  
    it "should include the request path" do
      expect(response).to include("/some/path")
    end
  
    it "should include the exception class" do
      expect(response).to include("ZeroDivisionError")
    end
    
    context "variable inspection" do
      let(:exception) { empty_binding.eval("raise") rescue $! }
      
      it "should show local variables" do
        html = error_page.do_variables("index" => 0)[:html]
        expect(html).to include("local_a")
        expect(html).to include(":value_for_local_a")
        expect(html).to include("local_b")
        expect(html).to include(":value_for_local_b")
      end
      
      it "should show instance variables" do
        html = error_page.do_variables("index" => 0)[:html]
        expect(html).to include("inst_c")
        expect(html).to include(":value_for_inst_c")
        expect(html).to include("inst_d")
        expect(html).to include(":value_for_inst_d")
      end
    end
    
    it "should not die if the source file is not a real filename" do
      exception.stub!(:backtrace).and_return([
        "<internal:prelude>:10:in `spawn_rack_application'"
      ])
      response.should include("Source unavailable")
    end
  end
end
