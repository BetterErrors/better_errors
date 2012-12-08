module BetterErrors
  class Middleware
    def initialize(app, handler = ErrorPage)
      @app      = app
      @handler  = handler
    end
    
    def call(env)
      @app.call env
    rescue Exception => ex
      error_page = @handler.new ex, env
      [500, { "Content-Type" => "text/html; charset=utf-8" }, [error_page.render]]
    end
  end
end
