# @private
module BetterErrors
  class RaisedException
    attr_reader :exception

    def initialize(exception, cause_index = 0)
      if exception.respond_to?(:original_exception) && exception.original_exception
        # This supports some specific Rails exceptions, and is not intended to act the same as `#cause`.
        exception = exception.original_exception
      end

      @exception = exception
      @cause_index = cause_index

      # FIXME: refactor massage_syntax_error so that it works without modifying instance variables
      # massage_syntax_error
    end

    attr_reader :cause_index

    def cause
      return unless exception.cause

      @cause ||= RaisedException.new(exception.cause, cause_index + 1)
    end

    def type
      exception.class
    end

    def frames
      exception.backtrace
    end

    def message
      exception.message.strip.gsub(/(\r?\n\s*\r?\n)+/, "\n")
    end

    def backtrace
      @backtrace ||= if has_bindings?
        backtrace_from_bindings
      else
        backtrace_from_backtrace
      end
    end

    def cleaned_backtrace
      if defined?(Rails) && defined?(Rails.backtrace_cleaner)
        Rails.backtrace_cleaner.clean backtrace.map(&:to_s)
      else
        backtrace
      end
    end

    def active_support_actions
      return [] unless defined?(ActiveSupport::ActionableError)

      ActiveSupport::ActionableError.actions(exception)
    end

    private

    def has_bindings?
      exception.respond_to?(:__better_errors_bindings_stack) && exception.__better_errors_bindings_stack.any?
    end

    def backtrace_from_bindings
      exception.__better_errors_bindings_stack.map { |binding|
        if binding.respond_to?(:source_location) # Ruby >= 2.6
          file = binding.source_location[0]
          line = binding.source_location[1]
        else
          file = binding.eval "__FILE__"
          line = binding.eval "__LINE__"
        end
        name = binding.frame_description
        StackFrame.new(file, line, name, binding)
      }
    end

    def backtrace_from_backtrace
      (exception.backtrace || []).map { |frame|
        if /\A(?<file>.*?):(?<line>\d+)(:in `(?<name>.*)')?/ =~ frame
          StackFrame.new(file, line.to_i, name)
        end
      }.compact
    end

    def massage_syntax_error
      case exception.class.to_s
      when "ActionView::Template::Error"
        if exception.respond_to?(:file_name) && exception.respond_to?(:line_number)
          backtrace.unshift(StackFrame.new(exception.file_name, exception.line_number.to_i, "view template"))
        end
      when "Haml::SyntaxError", "Sprockets::Coffeelint::Error"
        if /\A(.+?):(\d+)/ =~ exception.backtrace.first
          backtrace.unshift(StackFrame.new($1, $2.to_i, ""))
        end
      when "SyntaxError"
        if /\A(.+?):(\d+): (.*)/m =~ exception.message
          backtrace.unshift(StackFrame.new($1, $2.to_i, ""))
          @message = $3
        end
      end
    end
  end
end
