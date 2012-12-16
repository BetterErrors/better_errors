module BetterErrors
  # @private
  class DisableLoggingMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      original_level = BetterErrors.logger.level
      BetterErrors.logger.level = Logger::ERROR if env['PATH_INFO'].index("/__better_errors") == 0
      @app.call(env)
    ensure
      BetterErrors.logger.level = original_level
    end
  end
end