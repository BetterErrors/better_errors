require "json"

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
      case env["PATH_INFO"]
      when %r{\A/__better_errors/(?<oid>-?\d+)/(?<method>\w+)\z}
        internal_call env, $~
      when %r{\A/__better_errors/?\z}
        show_error_page env
      else
        app_call env
      end
    end
    
  private
    def app_call(env)
      @app.call env
    rescue Exception => ex
      @error_page = @handler.new ex, env
      log_exception
      show_error_page(env)
    end
    
    def show_error_page(env)
      content = if @error_page
        @error_page.render
      else
        "<h1>No errors</h1><p>No errors have been recorded yet.</p><hr>" +
        "<code>Better Errors v#{BetterErrors::VERSION}</code>"
      end

      [500, { "Content-Type" => "text/html; charset=utf-8" }, [content]]
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
      
      response = @error_page.send("do_#{opts[:method]}", JSON.parse(env["rack.input"].read))
      [200, { "Content-Type" => "text/plain; charset=utf-8" }, [JSON.dump(response)]]
    end
  end
end
