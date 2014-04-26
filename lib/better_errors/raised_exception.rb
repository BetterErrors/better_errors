# @private
module BetterErrors
  class RaisedException
    attr_reader :exception, :backtrace

    def initialize(exception)
      if exception.respond_to?(:original_exception) && exception.original_exception
        exception = exception.original_exception
      end

      @exception = exception

      setup_backtrace
    end

    def syntax_error?
      syntax_error_classes.any? { |klass| is_a?(klass) }
    end

  private
    def syntax_error_classes
      # Better Errors may be loaded before some of the gems that provide these
      # classes, so we lazily set up the set of syntax error classes at runtime
      # after everything has hopefully had a chance to load.
      #
      @syntax_error_classes ||= begin
        class_names = %w[
          SyntaxError
          Haml::SyntaxError
        ]

        class_names.map { |klass| eval(klass) rescue nil }.compact
      end
    end

    def has_bindings?
      exception.respond_to?(:__better_errors_bindings_stack) && exception.__better_errors_bindings_stack.any?
    end

    def setup_backtrace
      if has_bindings?
        setup_backtrace_from_bindings
      else
        setup_backtrace_from_backtrace
      end

      if syntax_error?
        if trace = exception.backtrace and trace.first =~ /\A(.*?):(\d+)/
          backtrace.unshift(StackFrame.new($1, $2.to_i, ""))
        end
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
  end
end
