# @private
module BetterErrors
  class RaisedException
    attr_reader :exception, :message, :backtrace, :hint

    def initialize(exception)
      if exception.class.name == "ActionView::Template::Error" && exception.respond_to?(:cause)
        # Rails 6+ exceptions of this type wrap the "real" exception, and the real exception
        # is actually more useful than the ActionView-provided wrapper. Once Better Errors
        # supports showing all exceptions in the cause stack, this should go away. Or perhaps
        # this can be changed to provide guidance by showing the second error in the cause stack
        # under this condition.
        exception = exception.cause if exception.cause
      elsif exception.respond_to?(:original_exception) && exception.original_exception
        # This supports some specific Rails exceptions, and this is not intended to act the same as
        # the Ruby's {Exception#cause}.
        # It's possible this should only support ActionView::Template::Error, but by not changing
        # this we're preserving longstanding behavior of Better Errors with Rails < 6.
        exception = exception.original_exception
      end

      @exception = exception
      @message = exception.message

      setup_backtrace
      setup_hint
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

    def setup_hint
      case exception
      when NoMethodError
        matches = /\Aundefined method `([^']+)' for ([^:]+):(\w+)\z/.match(message)
        if matches
          method = matches[1]
          val = matches[2]
          klass = matches[3]

          if val == "nil"
            @hint = "Something is `nil` when it probably shouldn't be."
          else
            @hint = "`#{method}` is being called on a `#{klass}`, which probably isn't the type you were expecting."
          end
        end
      when NameError
        matches = /\Aundefined local variable or method `([^']+)' for/.match(message)
        if matches
          method_or_var = matches[1]
          @hint = "`#{method_or_var}` is probably misspelled."
        end
      end
    end
  end
end
