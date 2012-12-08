module BetterErrors
  class Railtie < Rails::Railtie
    initializer "better_errors.configure_rails_initialization" do
      middleware = Rails.application.middleware
      middleware.use BetterErrors::Middleware
      
      BetterErrors.application_root = Rails.root.to_s
    end
  end
end
