require "pp"
require "erubis"
require "coderay"
require "uri"

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
    @editor
  end
  
  def editor=(editor)
    case editor
    when :textmate, :txmt, :tm
      self.editor = "txmt://open?url=file://%{file}&line=%{line}"
    when :sublime, :subl, :st
      self.editor = "subl://open?url=file://%{file}&line=%{line}"
    when :macvim, :mvim
      self.editor = "mvim://open?url=file://%{file}&line=%{line}"
    when String
      self.editor = proc { |file, line| editor % { file: URI.encode_www_form_component(file), line: line } }
    else
      if editor.respond_to? :call
        @editor = editor
      else
        raise TypeError, "Expected editor to be a valid editor key, a format string or a callable."
      end
    end
  end
  
  BetterErrors.editor = :textmate
end

begin
  $:.unshift "/Users/charlie/code/binding_of_caller/lib"
  require "binding_of_caller"
  BetterErrors.binding_of_caller_available = true
rescue LoadError => e
  BetterErrors.binding_of_caller_available = false
end

require "better_errors/core_ext/exception"

require "better_errors/rails" if defined? Rails::Railtie
