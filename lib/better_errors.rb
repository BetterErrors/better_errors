require "uri"

require "pp"
require "erubis"
require "coderay"

require "better_errors/version"
require "better_errors/error_page"
require "better_errors/stack_frame"
require "better_errors/middleware"
require "better_errors/disable_logging_middleware"
require "better_errors/code_formatter"
require "better_errors/repl"

class << BetterErrors
  attr_accessor :application_root, :binding_of_caller_available, :logger, :editor

  alias_method :binding_of_caller_available?, :binding_of_caller_available

  def editor
    # default to opening files in TextMate
    @editor || proc { |file, line| "txmt://open/?url=file://#{URI.encode_www_form_component(file)}&line=#{line}" }
  end
end

begin
  require "binding_of_caller"
  BetterErrors.binding_of_caller_available = true
rescue LoadError => e
  BetterErrors.binding_of_caller_available = false
end

unless BetterErrors.binding_of_caller_available?
  warn "BetterErrors: binding_of_caller gem unavailable, cannot display local variables on error pages."
  warn "Add 'binding_of_caller' to your Gemfile to make this warning go away."
  warn ""
end

require "better_errors/core_ext/exception"

require "better_errors/rails" if defined? Rails::Railtie
