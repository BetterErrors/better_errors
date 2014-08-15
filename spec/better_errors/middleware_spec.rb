require "spec_helper"

module BetterErrors
  describe Middleware do
    let(:app) { Middleware.new(->env { ":)" }) }
    let(:exception) { RuntimeError.new("oh no :(") }

    it "passes non-error responses through" do
      app.call({}).should == ":)"
    end

    it "calls the internal methods" do
      app.should_receive :internal_call
      app.call("PATH_INFO" => "/__better_errors/1/preform_awesomness")
    end

    it "calls the internal methods on any subfolder path" do
      app.should_receive :internal_call
      app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors/1/preform_awesomness")
    end

    it "shows the error page" do
      app.should_receive :show_error_page
      app.call("PATH_INFO" => "/__better_errors/")
    end

    it "shows the error page on any subfolder path" do
      app.should_receive :show_error_page
      app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors/")
    end

    it "doesn't show the error page to a non-local address" do
      app.should_not_receive :better_errors_call
      app.call("REMOTE_ADDR" => "1.2.3.4")
    end

    it "shows to a whitelisted IP" do
      BetterErrors::Middleware.allow_ip! '77.55.33.11'
      app.should_receive :better_errors_call
      app.call("REMOTE_ADDR" => "77.55.33.11")
    end

    it "respects the X-Forwarded-For header" do
      app.should_not_receive :better_errors_call
      app.call(
        "REMOTE_ADDR"          => "127.0.0.1",
        "HTTP_X_FORWARDED_FOR" => "1.2.3.4",
      )
    end

    it "doesn't blow up when given a blank REMOTE_ADDR" do
      expect { app.call("REMOTE_ADDR" => " ") }.to_not raise_error
    end

    it "doesn't blow up when given an IP address with a zone index" do
      expect { app.call("REMOTE_ADDR" => "0:0:0:0:0:0:0:1%0" ) }.to_not raise_error
    end

    context "when requesting the /__better_errors manually" do
      let(:app) { Middleware.new(->env { ":)" }) }

      it "shows that no errors have been recorded" do
        status, headers, body = app.call("PATH_INFO" => "/__better_errors")
        body.join.should match /No errors have been recorded yet./
      end

      it "shows that no errors have been recorded on any subfolder path" do
        status, headers, body = app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors")
        body.join.should match /No errors have been recorded yet./
      end
    end

    context "when handling an error" do
      let(:app) { Middleware.new(->env { raise exception }) }

      it "returns status 500" do
        status, headers, body = app.call({})

        status.should == 500
      end

      context "original_exception" do
        class OriginalExceptionException < Exception
          attr_reader :original_exception

          def initialize(message, original_exception = nil)
            super(message)
            @original_exception = original_exception
          end
        end

        it "shows Original Exception if it responds_to and has an original_exception" do
          app = Middleware.new(->env {
            raise OriginalExceptionException.new("Other Exception", Exception.new("Original Exception"))
          })

          status, _, body = app.call({})

          status.should == 500
          body.join.should_not match(/Other Exception/)
          body.join.should match(/Original Exception/)
        end

        it "won't crash if the exception responds_to but doesn't have an original_exception" do
          app = Middleware.new(->env {
            raise OriginalExceptionException.new("Other Exception")
          })

          status, _, body = app.call({})

          status.should == 500
          body.join.should match(/Other Exception/)
        end
      end

      it "returns ExceptionWrapper's status_code" do
        ad_ew = double("ActionDispatch::ExceptionWrapper")
        ad_ew.stub('new').with({}, exception ){ double("ExceptionWrapper", status_code: 404) }
        stub_const('ActionDispatch::ExceptionWrapper', ad_ew)

        status, headers, body = app.call({})

        status.should == 404
      end

      it "returns UTF-8 error pages" do
        status, headers, body = app.call({})

        headers["Content-Type"].should match /charset=utf-8/
      end

      it "returns text pages by default" do
        status, headers, body = app.call({})

        headers["Content-Type"].should match /text\/plain/
      end

      it "returns HTML pages by default" do
        # Chrome's 'Accept' header looks similar this.
        status, headers, body = app.call("HTTP_ACCEPT" => "text/html,application/xhtml+xml;q=0.9,*/*")

        headers["Content-Type"].should match /text\/html/
      end

      it "logs the exception" do
        logger = Object.new
        logger.should_receive :fatal
        BetterErrors.stub(:logger).and_return(logger)

        app.call({})
      end
    end
  end
end
