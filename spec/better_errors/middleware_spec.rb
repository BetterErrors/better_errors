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

    it "shows to a whitelisted IPAddr" do
      BetterErrors::Middleware.allow_ip! IPAddr.new('77.55.33.0/24')
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
        expect(ad_ew).to_not receive :new

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

      context "when the exception has a cause" do
        before do
          pending "This Ruby does not support `cause`" unless Exception.new.respond_to?(:cause)
        end

        let(:app) {
          Middleware.new(->env {
            begin
              raise "First Exception"
            rescue
              raise "Second Exception"
            end
          })
        }

        it "shows the exception as-is" do
          status, _, body = app.call({})

          expect(status).to eq(500)
          expect(body.join).to match(/\n> Second Exception\n/)
          expect(body.join).not_to match(/\n> First Exception\n/)
        end
      end

      context "when the exception responds to #original_exception" do
        class OriginalExceptionException < Exception
          attr_reader :original_exception

          def initialize(message, original_exception = nil)
            super(message)
            @original_exception = original_exception
          end
        end

        context 'and has one' do
          let(:app) {
            Middleware.new(->env {
              raise OriginalExceptionException.new("Second Exception", Exception.new("First Exception"))
            })
          }

          it "shows the original exception instead of the last-raised one" do
            status, _, body = app.call({})

            expect(status).to eq(500)
            expect(body.join).not_to match(/Second Exception/)
            expect(body.join).to match(/First Exception/)
          end
        end

        context 'and does not have one' do
          let(:app) {
            Middleware.new(->env {
              raise OriginalExceptionException.new("The Exception")
            })
          }

          it "shows the exception as-is" do
            status, _, body = app.call({})

            expect(status).to eq(500)
            expect(body.join).to match(/The Exception/)
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

      context 'the logger' do
        let(:logger) { double('logger', fatal: nil) }
        before do
          allow(BetterErrors).to receive(:logger).and_return(logger)
        end

        it "receives the exception as a fatal message" do
          expect(logger).to receive(:fatal).with(/RuntimeError/)
          app.call({})
        end

        context 'when Rails is being used' do
          before do
            skip("Rails not included in this run") unless defined? Rails
          end

          it "receives the exception without filtered backtrace frames" do
            expect(logger).to receive(:fatal) do |message|
              expect(message).to_not match(/rspec-core/)
            end
            app.call({})
          end
        end
        context 'when Rails is not being used' do
          before do
            skip("Rails is included in this run") if defined? Rails
          end

          it "receives the exception with all backtrace frames" do
            expect(logger).to receive(:fatal) do |message|
              expect(message).to match(/rspec-core/)
            end
            app.call({})
          end
        end
      end
    end

    context "requesting the variables for a specific frame" do
      let(:env) { {} }
      let(:result) {
        app.call(
          "PATH_INFO" => "/__better_errors/#{id}/#{method}",
          # This is a POST request, and this is the body of the request.
          "rack.input" => StringIO.new('{"index": 0}'),
        )
      }
      let(:status) { result[0] }
      let(:headers) { result[1] }
      let(:body) { result[2].join }
      let(:json_body) { JSON.parse(body) }
      let(:id) { 'abcdefg' }
      let(:method) { 'variables' }

      context 'when no errors have been recorded' do
        it 'returns a JSON error' do
          expect(json_body).to match(
            'error' => 'No exception information available',
            'explanation' => /application has been restarted/,
          )
        end

        context 'when Middleman is in use' do
          let!(:middleman) { class_double("Middleman").as_stubbed_const }
          it 'returns a JSON error' do
            expect(json_body['explanation'])
              .to match(/Middleman reloads all dependencies/)
          end
        end

        context 'when Shotgun is in use' do
          let!(:shotgun) { class_double("Shotgun").as_stubbed_const }

          it 'returns a JSON error' do
            expect(json_body['explanation'])
              .to match(/The shotgun gem/)
          end

          context 'when Hanami is also in use' do
            let!(:hanami) { class_double("Hanami").as_stubbed_const }
            it 'returns a JSON error' do
              expect(json_body['explanation'])
                .to match(/--no-code-reloading/)
            end
          end
        end
      end

      context 'when an error has been recorded' do
        let(:error_page) { ErrorPage.new(exception, env) }
        before do
          app.instance_variable_set('@error_page', error_page)
        end

        context 'but it does not match the request' do
          it 'returns a JSON error' do
            expect(json_body).to match(
              'error' => 'Session expired',
              'explanation' => /no longer available in memory/,
            )
          end
        end

        context 'and it matches the request', :focus do
          let(:id) { error_page.id }

          it 'returns a JSON error' do
            expect(error_page).to receive(:do_variables).and_return(html: "<content>")
            expect(json_body).to match(
              'html' => '<content>',
            )
          end
        end
      end
    end
  end
end
