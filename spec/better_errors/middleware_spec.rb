require "spec_helper"

module BetterErrors
  describe Middleware do
    let(:app) { Middleware.new(->env { ":)" }) }

    it "should pass non-error responses through" do
      app.call({}).should == ":)"
    end

    it "should call the internal methods" do
      app.should_receive :internal_call
      app.call("PATH_INFO" => "/__better_errors/1/preform_awesomness")
    end

    it "should show the error page" do
      app.should_receive :show_error_page
      app.call("PATH_INFO" => "/__better_errors/")
    end

    context "when requesting the /__better_errors manually" do
      let(:app) { Middleware.new(->env { ":)" }) }
      
      it "should show that no errors have been recorded" do
        status, headers, body = app.call("PATH_INFO" => "/__better_errors")
        body.join.should match /No errors have been recorded yet./
      end
    end
    
    context "when handling an error" do
      let(:app) { Middleware.new(->env { raise "oh no :(" }) }
    
      it "should return status 500" do
        status, headers, body = app.call({})
      
        status.should == 500
      end
    
      it "should return UTF-8 error pages" do
        status, headers, body = app.call({})
        
        headers["Content-Type"].should == "text/html; charset=utf-8"
      end
      
      it "should log the exception" do
        logger = Object.new
        logger.should_receive :fatal
        BetterErrors.stub!(:logger).and_return(logger)
        
        app.call({})
      end
    end
  end
end
