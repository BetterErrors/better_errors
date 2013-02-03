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

    it "should not show the error page to a non-local address" do
      app.should_not_receive :better_errors_call
      app.call("REMOTE_ADDR" => "1.2.3.4")
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

      shared_examples_for 'middleware handling an error' do
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

    if RUBY_PLATFORM == 'java'
      require 'java'

      context "when native java exception is raised" do

        let(:app) { Middleware.new(->env { java.lang.Integer.parseInt("") }) }

        it_should_behave_like 'middleware handling an error'
      end

      context "when native java exception is raised from ruby" do

        let(:app) { Middleware.new(->env { raise java.lang.Exception.new('jruby native error') }) }

        it_should_behave_like 'middleware handling an error'
      end

    end

  end
end
