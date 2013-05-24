module BetterErrors
  # @private
  class Railtie < Rails::Railtie

    config.better_errors = ActiveSupport::OrderedOptions.new

    initializer "better_errors.configure_rails_initialization" do
      if use_better_errors?
        insert_middleware
        BetterErrors.logger = Rails.logger
        BetterErrors.application_root = Rails.root.to_s
        BetterErrors.uri_prefix = config.better_errors.uri_prefix if config.better_errors.uri_prefix
      end
    end

    def insert_middleware
      if defined? ActionDispatch::DebugExceptions
        app.middleware.insert_after ActionDispatch::DebugExceptions, BetterErrors::Middleware
      else
        app.middleware.use BetterErrors::Middleware
      end
    end

    def use_better_errors?
      !Rails.env.production? and app.config.consider_all_requests_local
    end

    def app
      Rails.application
    end
  end
end
