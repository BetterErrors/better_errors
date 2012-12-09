module BetterErrors
  class Railtie < Rails::Railtie
    initializer "better_errors.configure_rails_initialization" do
      unless Rails.env.production?
        Rails.application.middleware.use BetterErrors::Middleware
        BetterErrors.application_root = Rails.root.to_s
      end
    end
  end
end
