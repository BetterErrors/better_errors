module BetterErrors
  # @private
  class Railtie < Rails::Railtie
    initializer "better_errors.configure_rails_initialization" do
      unless Rails.env.production?
        insert_middleware
        BetterErrors.logger = Rails.logger
        BetterErrors.application_root = Rails.root.to_s
      end
    end

    def insert_middleware
      if defined? ActionDispatch::DebugExceptions
        Rails.application.middleware.insert_after ActionDispatch::DebugExceptions, BetterErrors::Middleware
      else
        Rails.application.middleware.use BetterErrors::Middleware
      end
    end
  end
end
