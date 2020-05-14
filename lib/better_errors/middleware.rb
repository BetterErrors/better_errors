require "json"
require "ipaddr"
require "set"
require "rack"

module BetterErrors
  # Better Errors' error handling middleware. Including this in your middleware
  # stack will show a Better Errors error page for exceptions raised below this
  # middleware.
  #
  # If you are using Ruby on Rails, you do not need to manually insert this
  # middleware into your middleware stack.
  #
  # @example Sinatra
  #   require "better_errors"
  #
  #   if development?
  #     use BetterErrors::Middleware
  #   end
  #
  # @example Rack
  #   require "better_errors"
  #   if ENV["RACK_ENV"] == "development"
  #     use BetterErrors::Middleware
  #   end
  #
  class Middleware
    # The set of IP addresses that are allowed to access Better Errors.
    #
    # Set to `{ "127.0.0.1/8", "::1/128" }` by default.
    ALLOWED_IPS = Set.new

    # Adds an address to the set of IP addresses allowed to access Better
    # Errors.
    def self.allow_ip!(addr)
      ALLOWED_IPS << (addr.is_a?(IPAddr) ? addr : IPAddr.new(addr))
    end

    allow_ip! "127.0.0.0/8"
    allow_ip! "::1/128" rescue nil # windows ruby doesn't have ipv6 support

    # A new instance of BetterErrors::Middleware
    #
    # @param app      The Rack app/middleware to wrap with Better Errors
    # @param handler  The error handler to use.
    def initialize(app, handler = ErrorPage)
      @app      = app
      @handler  = handler
    end

    # Calls the Better Errors middleware
    #
    # @param [Hash] env
    # @return [Array]
    def call(env)
      if allow_ip? env
        better_errors_call env
      else
        @app.call env
      end
    end

  private

    def allow_ip?(env)
      request = Rack::Request.new(env)
      return true unless request.ip and !request.ip.strip.empty?
      ip = IPAddr.new request.ip.split("%").first
      ALLOWED_IPS.any? { |subnet| subnet.include? ip }
    end

    def better_errors_call(env)
      case env["PATH_INFO"]
      when %r{/__better_errors/cause/(?<cause_index>.+)\z}
        show_error_page_for_cause_index(env, $~[:cause_index])
      when %r{/__better_errors/(?<id>.+?)/(?<method>\w+)\z}
        internal_call(env, $~[:id], $~[:method])
      when %r{/__better_errors/?\z}
        show_error_page env
      else
        protected_app_call env
      end
    end

    def protected_app_call(env)
      @app.call env
    rescue Exception => ex
      @error_state = ErrorState.new(ex, env)
      log_exception
      show_error_page_with_exception_status_code env
    end

    ##
    # Responds with the error page and a 500 status code
    # (or a different status if Rails provides a status code for the specific exception).
    def show_error_page_with_exception_status_code(env)
      type, content = error_page_type_and_content(env, ErrorPage.new(@error_state))

      status_code = 500
      if defined?(ActionDispatch::ExceptionWrapper)
        status_code = ActionDispatch::ExceptionWrapper.new(env, @error_state.top_exception).status_code
      end

      [status_code, { "Content-Type" => "text/#{type}; charset=utf-8" }, [content]]
    end

    ##
    # Responds with the error page and a 200 status code. Used when the user visits /__better_errors
    def show_error_page(env)
      type, content = error_page_type_and_content(env, ErrorPage.new(@error_state))

      status_code = 200
      [status_code, { "Content-Type" => "text/#{type}; charset=utf-8" }, [content]]
    end

    ##
    # Responds with the error page for a specific exception cause index.
    def show_error_page_for_cause_index(env, cause_index)
      type, content = error_page_type_and_content(env, ErrorPage.new(@error_state, cause_index))

      status_code = 500
      if defined?(ActionDispatch::ExceptionWrapper)
        status_code = ActionDispatch::ExceptionWrapper.new(env, @error_state.top_exception).status_code
      end

      [status_code, { "Content-Type" => "text/#{type}; charset=utf-8" }, [content]]
    end

    def error_page_type_and_content(env, error_page)
      if @error_state
        if text?(env)
          [ 'plain', error_page.render('text') ]
        else
          [ 'html', error_page.render ]
        end
      else
        [ 'html', no_errors_page ]
      end
    end

    def text?(env)
      env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" || !env["HTTP_ACCEPT"].to_s.include?('html')
    end

    def log_exception
      return unless BetterErrors.logger

      # TODO: recursively print exception with cause
      message = "\n#{@error_state.top_exception.type} - #{@error_state.top_exception.message}:\n"
      message += @error_state.top_exception.cleaned_backtrace.map { |frame| "  #{frame}\n" }.join

      BetterErrors.logger.fatal message
    end

    def internal_call(env, error_id, method_name)
      return no_errors_json_response unless @error_state
      return invalid_error_json_response if error_id != @error_state.id

      env["rack.input"].rewind
      error_page = ErrorPage.new(@error_state)
      response = error_page.send("do_#{method_name}", JSON.parse(env["rack.input"].read))
      [200, { "Content-Type" => "text/plain; charset=utf-8" }, [JSON.dump(response)]]
    end

    def no_errors_page
      "<h1>No errors</h1><p>No errors have been recorded yet.</p><hr>" +
      "<code>Better Errors v#{BetterErrors::VERSION}</code>"
    end

    def no_errors_json_response
      explanation = if defined? Middleman
        "Middleman reloads all dependencies for each request, " +
          "which breaks Better Errors."
      elsif defined?(Shotgun) && defined?(Hanami)
        "Hanami is likely running with code-reloading enabled, which is the default. " +
          "You can disable this by running hanami with the `--no-code-reloading` option."
      elsif defined? Shotgun
        "The shotgun gem causes everything to be reloaded for every request. " +
          "You can disable shotgun in the Gemfile temporarily to use Better Errors."
      else
        "The application has been restarted since this page loaded, " +
          "or the framework is reloading all gems before each request "
      end
      [200, { "Content-Type" => "text/plain; charset=utf-8" }, [JSON.dump(
        error: 'No exception information available',
        explanation: explanation,
      )]]
    end

    def invalid_error_json_response
      [200, { "Content-Type" => "text/plain; charset=utf-8" }, [JSON.dump(
        error: "Session expired",
        explanation: "This page was likely opened from a previous exception, " +
          "and the exception is no longer available in memory.",
      )]]
    end
  end
end
