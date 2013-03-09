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

    it "should call the internal methods on any subfolder path" do
      app.should_receive :internal_call
      app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors/1/preform_awesomness")
    end

    it "should show the error page" do
      app.should_receive :show_error_page
      app.call("PATH_INFO" => "/__better_errors/")
    end

    it "should show the error page on any subfolder path" do
      app.should_receive :show_error_page
      app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors/")
    end

    it "should not show the error page to a non-local address" do
      app.should_not_receive :better_errors_call
      app.call("REMOTE_ADDR" => "1.2.3.4")
    end

    it "should show to a whitelisted IP" do
      BetterErrors::Middleware.allow_ip! '77.55.33.11'
      app.should_receive :better_errors_call
      app.call("REMOTE_ADDR" => "77.55.33.11")
    end

    context "when requesting the /__better_errors manually" do
      let(:app) { Middleware.new(->env { ":)" }) }

      it "should show that no errors have been recorded" do
        status, headers, body = app.call("PATH_INFO" => "/__better_errors")
        body.join.should match /No errors have been recorded yet./
      end

      it "should show that no errors have been recorded on any subfolder path" do
        status, headers, body = app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors")
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

        headers["Content-Type"].should match /charset=utf-8/
      end

      it "should return text pages by default" do
        status, headers, body = app.call({})

        headers["Content-Type"].should match /text\/plain/
      end

      it "should return HTML pages by default" do
        # Chrome's 'Accept' header looks similar this.
        status, headers, body = app.call("HTTP_ACCEPT" => "text/html,application/xhtml+xml;q=0.9,*/*")

        headers["Content-Type"].should match /text\/html/
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
