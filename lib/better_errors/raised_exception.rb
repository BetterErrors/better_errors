# @private
module BetterErrors
  class RaisedException
    attr_reader :exception, :message, :backtrace

    def initialize(exception)
      if exception.respond_to?(:original_exception) && exception.original_exception
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
        file = binding.eval "__FILE__"
        line = binding.eval "__LINE__"
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
      when "Haml::SyntaxError"
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
