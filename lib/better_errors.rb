require "erubis"
require "coderay"

require "better_errors/version"
require "better_errors/error_page"
require "better_errors/error_frame"
require "better_errors/middleware"

class << BetterErrors
  attr_accessor :application_root
end

require "better_errors/rails" if defined? Rails::Railtie
