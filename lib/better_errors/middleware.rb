require "json"

module BetterErrors
  class Middleware
    def initialize(app, handler = ErrorPage)
      @app      = app
      @handler  = handler
    end
    
    def call(env)
      if env["REQUEST_PATH"] =~ %r{\A/__better_errors/(?<oid>\d+)/(?<method>\w+)\z}
        internal_call env, $~
      else
        app_call env
      end
    end
    
  private
    def app_call(env)
      @app.call env
    rescue Exception => ex
      @error_page = @handler.new ex, env
      [500, { "Content-Type" => "text/html; charset=utf-8" }, [@error_page.render]]
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
