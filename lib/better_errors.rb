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

  # Return default url for open in
  # editor functionality.
  # Can override by setting
  # BetterErrors.editor = Proc.new{|file, line|
  #   "mvim://open/?url=file://#{URI.escape file}&line=#{line}"
  # }
  #
  def editor
    @editor || proc { |file, line| "txmt://open/?url=file://#{URI.encode_www_form_component(file)}&line=#{line}" }
  end
end

# Check if the gem binding_of_caller
# is available on Gemfile
#
begin
  require "binding_of_caller"
  BetterErrors.binding_of_caller_available = true
rescue LoadError => e
  BetterErrors.binding_of_caller_available = false
end

# Display message if 'binding_of_caller'
# is not on Gemfile
#
unless BetterErrors.binding_of_caller_available?
  warn "BetterErrors: binding_of_caller gem unavailable, cannot display local variables on error pages."
  warn "Add 'binding_of_caller' to your Gemfile to make this warning go away."
  warn ""
end

require "better_errors/core_ext/exception"

require "better_errors/rails" if defined? Rails::Railtie
