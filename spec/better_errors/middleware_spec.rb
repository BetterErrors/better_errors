require "spec_helper"

module BetterErrors
  describe Middleware do
    it "should pass non-error responses through" do
      app = Middleware.new(->env { ":)" })
      app.call({}).should == ":)"
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
