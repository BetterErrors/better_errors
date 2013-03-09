require "json"
require "ipaddr"
require "set"

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
      ALLOWED_IPS << IPAddr.new(addr)
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
      # REMOTE_ADDR is not in the rack spec, so some application servers do
      # not provide it.
      return true unless env["REMOTE_ADDR"]
      ip = IPAddr.new env["REMOTE_ADDR"]
      ALLOWED_IPS.any? { |subnet| subnet.include? ip }
    end

    def better_errors_call(env)
      case env["PATH_INFO"]
      when %r{/__better_errors/(?<oid>-?\d+)/(?<method>\w+)\z}
        internal_call env, $~
      when %r{/__better_errors/?\z}
        show_error_page env
      else
        protected_app_call env
      end
    end

    def protected_app_call(env)
      @app.call env
    rescue Exception => ex
      @error_page = @handler.new ex, env
      log_exception
      show_error_page(env)
    end

    def show_error_page(env)
      type, content = if @error_page
        if text?(env)
          [ 'plain', @error_page.render('text') ]
        else
          [ 'html', @error_page.render ]
        end
      else
        [ 'html', no_errors_page ]
      end

      [500, { "Content-Type" => "text/#{type}; charset=utf-8" }, [content]]
    end

    def text?(env)
      env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" ||
      !env["HTTP_ACCEPT"].to_s.include?('html')
    end

    def log_exception
      return unless BetterErrors.logger

      message = "\n#{@error_page.exception.class} - #{@error_page.exception.message}:\n"
      @error_page.backtrace_frames.each do |frame|
        message << "  #{frame}\n"
      end

      BetterErrors.logger.fatal message
    end

    def internal_call(env, opts)
      if opts[:oid].to_i != @error_page.object_id
        return [200, { "Content-Type" => "text/plain; charset=utf-8" }, [JSON.dump(error: "Session expired")]]
      end

      env["rack.input"].rewind
      response = @error_page.send("do_#{opts[:method]}", JSON.parse(env["rack.input"].read))
      [200, { "Content-Type" => "text/plain; charset=utf-8" }, [JSON.dump(response)]]
    end

    def no_errors_page
      "<h1>No errors</h1><p>No errors have been recorded yet.</p><hr>" +
      "<code>Better Errors v#{BetterErrors::VERSION}</code>"
    end
  end
end
