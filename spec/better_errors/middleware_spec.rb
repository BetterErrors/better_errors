require "spec_helper"

module BetterErrors
  describe Middleware do
    let(:app) { Middleware.new(->env { ":)" }) }
    let(:exception) { RuntimeError.new("oh no :(") }

    it "passes non-error responses through" do
      expect(app.call({})).to eq(":)")
    end

    it "calls the internal methods" do
      expect(app).to receive :internal_call
      app.call("PATH_INFO" => "/__better_errors/1/preform_awesomness")
    end

    it "calls the internal methods on any subfolder path" do
      expect(app).to receive :internal_call
      app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors/1/preform_awesomness")
    end

    it "shows the error page" do
      expect(app).to receive :show_error_page
      app.call("PATH_INFO" => "/__better_errors/")
    end

    it "shows the error page on any subfolder path" do
      expect(app).to receive :show_error_page
      app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors/")
    end

    it "doesn't show the error page to a non-local address" do
      expect(app).not_to receive :better_errors_call
      app.call("REMOTE_ADDR" => "1.2.3.4")
    end

    it "shows to a whitelisted IP" do
      BetterErrors::Middleware.allow_ip! '77.55.33.11'
      expect(app).to receive :better_errors_call
      app.call("REMOTE_ADDR" => "77.55.33.11")
    end

    it "respects the X-Forwarded-For header" do
      expect(app).not_to receive :better_errors_call
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
        expect(body.join).to match /No errors have been recorded yet./
      end

      it 'does not attempt to use ActionDispatch::ExceptionWrapper with a nil exception' do
        ad_ew = double("ActionDispatch::ExceptionWrapper")
        stub_const('ActionDispatch::ExceptionWrapper', ad_ew)
        ad_ew.should_not_receive :new

        status, headers, body = app.call("PATH_INFO" => "/__better_errors")
      end

      it "shows that no errors have been recorded on any subfolder path" do
        status, headers, body = app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors")
        expect(body.join).to match /No errors have been recorded yet./
      end
    end

    context "when handling an error" do
      let(:app) { Middleware.new(->env { raise exception }) }

      it "returns status 500" do
        status, headers, body = app.call({})

        expect(status).to eq(500)
      end

      if Exception.new.respond_to?(:cause)
        context "cause" do
          class OtherException < Exception
            def initialize(message)
              super(message)
            end
          end

          it "shows Original Exception if it responds_to and has an cause" do
            app = Middleware.new(->env {
              begin
                raise "Original Exception"
              rescue
                raise OtherException.new("Other Exception")
              end
            })

            status, _, body = app.call({})

            expect(status).to eq(500)
            expect(body.join).not_to match(/\n> Other Exception\n/)
            expect(body.join).to match(/\n> Original Exception\n/)
          end
        end
      else
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

            expect(status).to eq(500)
            expect(body.join).not_to match(/Other Exception/)
            expect(body.join).to match(/Original Exception/)
          end

          it "won't crash if the exception responds_to but doesn't have an original_exception" do
            app = Middleware.new(->env {
              raise OriginalExceptionException.new("Other Exception")
            })

            status, _, body = app.call({})

            expect(status).to eq(500)
            expect(body.join).to match(/Other Exception/)
          end
        end
      end

      it "returns ExceptionWrapper's status_code" do
        ad_ew = double("ActionDispatch::ExceptionWrapper")
        allow(ad_ew).to receive('new').with({}, exception) { double("ExceptionWrapper", status_code: 404) }
        stub_const('ActionDispatch::ExceptionWrapper', ad_ew)

        status, headers, body = app.call({})

        expect(status).to eq(404)
      end

      it "returns UTF-8 error pages" do
        status, headers, body = app.call({})

        expect(headers["Content-Type"]).to match /charset=utf-8/
      end

      it "returns text pages by default" do
        status, headers, body = app.call({})

        expect(headers["Content-Type"]).to match /text\/plain/
      end

      it "returns HTML pages by default" do
        # Chrome's 'Accept' header looks similar this.
        status, headers, body = app.call("HTTP_ACCEPT" => "text/html,application/xhtml+xml;q=0.9,*/*")

        expect(headers["Content-Type"]).to match /text\/html/
      end

      it "logs the exception" do
        logger = Object.new
        expect(logger).to receive :fatal
        allow(BetterErrors).to receive(:logger).and_return(logger)

        app.call({})
      end
    end
  end
end
