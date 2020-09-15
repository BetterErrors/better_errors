require "spec_helper"

module BetterErrors
  describe Middleware do
    let(:app) { Middleware.new(->env { ":)" }) }
    let(:exception) { RuntimeError.new("oh no :(") }
    let(:status) { response_env[0] }
    let(:headers) { response_env[1] }
    let(:body) { response_env[2].join }

    context 'when the application raises no exception' do
      it "passes non-error responses through" do
        expect(app.call({})).to eq(":)")
      end
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

    context "when /__better_errors is requested directly" do
      let(:response_env) { app.call("PATH_INFO" => "/__better_errors") }

      context "when no error has been recorded since startup" do
        it "shows that no errors have been recorded" do
          expect(body).to match /No errors have been recorded yet./
        end

        it 'does not attempt to use ActionDispatch::ExceptionWrapper on the nil exception' do
          ad_ew = double("ActionDispatch::ExceptionWrapper")
          stub_const('ActionDispatch::ExceptionWrapper', ad_ew)
          expect(ad_ew).to_not receive :new

          response_env
        end

        context 'when requested inside a subfolder path' do
          let(:response_env) { app.call("PATH_INFO" => "/any_sub/folder/__better_errors") }

          it "shows that no errors have been recorded" do
            expect(body).to match /No errors have been recorded yet./
          end
        end
      end

      context 'when an error has been recorded' do
        let(:app) {
          Middleware.new(->env do
            # Only raise on the first request
            raise exception unless @already_raised
            @already_raised = true
          end)
        }
        before do
          app.call({})
        end

        it 'returns the information of the most recent error' do
          expect(body).to include("oh no :(")
        end

        it 'does not attempt to use ActionDispatch::ExceptionWrapper' do
          ad_ew = double("ActionDispatch::ExceptionWrapper")
          stub_const('ActionDispatch::ExceptionWrapper', ad_ew)
          expect(ad_ew).to_not receive :new

          response_env
        end

        context 'when inside a subfolder path' do
          let(:response_env) { app.call("PATH_INFO" => "/any_sub/folder/__better_errors") }

          it "shows the error page on any subfolder path" do
            expect(app).to receive :show_error_page
            app.call("PATH_INFO" => "/any_sub/folder/path/__better_errors/")
          end
        end
      end
    end

    context "when handling an error" do
      let(:app) { Middleware.new(->env { raise exception }) }
      let(:response_env) { app.call({}) }

      it "returns status 500" do
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
          expect(status).to eq(500)
          expect(body).to match(/\n> Second Exception\n/)
          expect(body).not_to match(/\n> First Exception\n/)
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
            expect(status).to eq(500)
            expect(body).not_to match(/Second Exception/)
            expect(body).to match(/First Exception/)
          end
        end

        context 'and does not have one' do
          let(:app) {
            Middleware.new(->env {
              raise OriginalExceptionException.new("The Exception")
            })
          }

          it "shows the exception as-is" do
            expect(status).to eq(500)
            expect(body).to match(/The Exception/)
          end
        end
      end

      it "returns ExceptionWrapper's status_code" do
        ad_ew = double("ActionDispatch::ExceptionWrapper")
        allow(ad_ew).to receive('new').with(anything, exception) { double("ExceptionWrapper", status_code: 404) }
        stub_const('ActionDispatch::ExceptionWrapper', ad_ew)

        expect(status).to eq(404)
      end

      it "returns UTF-8 error pages" do
        expect(headers["Content-Type"]).to match /charset=utf-8/
      end

      it "returns text content by default" do
        expect(headers["Content-Type"]).to match /text\/plain/
      end

      context 'when a CSRF token cookie is not specified' do
        it 'includes a newly-generated CSRF token cookie' do
          expect(headers).to include(
            'Set-Cookie' => /BetterErrors-CSRF-Token=[-a-z0-9]+; HttpOnly; SameSite=Strict/
          )
        end
      end

      context 'when a CSRF token cookie is specified' do
        let(:response_env) { app.call({ 'HTTP_COOKIE' => 'BetterErrors-CSRF-Token=abc123' }) }

        it 'does not set a new CSRF token cookie' do
          expect(headers).not_to include('Set-Cookie')
        end
      end

      context 'when the Accept header specifies HTML first' do
        let(:response_env) { app.call("HTTP_ACCEPT" => "text/html,application/xhtml+xml;q=0.9,*/*") }

        it "returns HTML content" do
          expect(headers["Content-Type"]).to match /text\/html/
        end

        it 'includes the newly-generated CSRF token in the body of the page' do
          matches = headers['Set-Cookie'].match(/BetterErrors-CSRF-Token=(?<tok>[-a-z0-9]+); HttpOnly; SameSite=Strict/)
          expect(body).to include(matches[:tok])
        end

        context 'when a CSRF token cookie is specified' do
          let(:response_env) {
            app.call({
              'HTTP_COOKIE' => 'BetterErrors-CSRF-Token=csrfTokenGHI',
              "HTTP_ACCEPT" => "text/html,application/xhtml+xml;q=0.9,*/*",
            })
          }

          it 'includes that CSRF token in the body of the page' do
            expect(body).to include('csrfTokenGHI')
          end
        end
      end

      context 'the logger' do
        let(:logger) { double('logger', fatal: nil) }
        before do
          allow(BetterErrors).to receive(:logger).and_return(logger)
        end

        it "receives the exception as a fatal message" do
          expect(logger).to receive(:fatal).with(/RuntimeError/)
          response_env
        end

        context 'when Rails is being used' do
          before do
            skip("Rails not included in this run") unless defined? Rails
          end

          it "receives the exception without filtered backtrace frames" do
            expect(logger).to receive(:fatal) do |message|
              expect(message).to_not match(/rspec-core/)
            end
            response_env
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
            response_env
          end
        end
      end
    end

    context "requesting the variables for a specific frame" do
      let(:env) { {} }
      let(:response_env) {
        app.call(request_env)
      }
      let(:request_env) {
        Rack::MockRequest.env_for("/__better_errors/#{id}/variables", input: StringIO.new(JSON.dump(request_body_data)))
      }
      let(:request_body_data) { {"index": 0} }
      let(:json_body) { JSON.parse(body) }
      let(:id) { 'abcdefg' }

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

        context 'and its ID matches the requested ID' do
          let(:id) { error_page.id }

          context 'when the body csrfToken matches the CSRF token cookie' do
            let(:request_body_data) { { "index" => 0, "csrfToken" => "csrfToken123" } }
            before do
              request_env["HTTP_COOKIE"] = "BetterErrors-CSRF-Token=csrfToken123"
            end

            it 'returns the HTML content' do
              expect(error_page).to receive(:do_variables).and_return(html: "<content>")
              expect(json_body).to match(
                'html' => '<content>',
              )
            end
          end

          context 'when the body csrfToken does not match the CSRF token cookie' do
            let(:request_body_data) { {"index": 0, "csrfToken": "csrfToken123"} }
            before do
              request_env["HTTP_COOKIE"] = "BetterErrors-CSRF-Token=csrfToken456"
            end

            it 'returns a JSON error' do
              expect(json_body).to match(
                'error' => 'Invalid CSRF Token',
                'explanation' => /session might have been cleared/,
              )
            end
          end

          context 'when there is no CSRF token in the request' do
            it 'returns a JSON error' do
              expect(json_body).to match(
                'error' => 'Invalid CSRF Token',
                'explanation' => /session might have been cleared/,
              )
            end
          end
        end
      end
    end
  end
end
