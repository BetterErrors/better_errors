# @private
module BetterErrors
  class RaisedException
    attr_reader :exception, :message, :backtrace

    def initialize(exception)
      if exception.respond_to?(:original_exception) && exception.original_exception
        # This supports some specific Rails exceptions, and is not intended to act the same as `#cause`.
        exception = exception.original_exception
      end

      @exception = exception
      @message = exception.message

      setup_backtrace
      massage_syntax_error
    end

    def type
      exception.class
    end

  private
    def has_bindings?
      exception.respond_to?(:__better_errors_bindings_stack) && exception.__better_errors_bindings_stack.any?
    end

    def setup_backtrace
      if has_bindings?
        setup_backtrace_from_bindings
      else
        setup_backtrace_from_backtrace
      end
    end

    def setup_backtrace_from_bindings
      @backtrace = exception.__better_errors_bindings_stack.map { |binding|
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

    def setup_backtrace_from_backtrace
      @backtrace = (exception.backtrace || []).map { |frame|
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
