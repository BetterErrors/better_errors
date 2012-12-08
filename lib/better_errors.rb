require "pp"
require "erubis"
require "coderay"

require "better_errors/version"
require "better_errors/error_page"
require "better_errors/error_frame"
require "better_errors/middleware"

class << BetterErrors
  attr_accessor :application_root, :binding_of_caller_available
  
  alias_method :binding_of_caller_available?, :binding_of_caller_available
end

begin
  require "binding_of_caller"
  BetterErrors.binding_of_caller_available = true
rescue LoadError => e
  BetterErrors.binding_of_caller_available = false
end

if BetterErrors.binding_of_caller_available?
  require "better_errors/core_ext/exception"
else
  warn "BetterErrors: binding_of_caller gem unavailable, cannot display local variables on error pages."
  warn "Add 'binding_of_caller' to your Gemfile to make this warning go away."
  warn ""
end

require "better_errors/rails" if defined? Rails::Railtie
