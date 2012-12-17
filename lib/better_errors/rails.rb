module BetterErrors
  # @private
  class Railtie < Rails::Railtie
    initializer "better_errors.configure_rails_initialization" do
      unless Rails.env.production?
        Rails.application.middleware.use BetterErrors::Middleware
        BetterErrors.logger = Rails.logger
        BetterErrors.application_root = Rails.root.to_s
      end
    end
  end
end
