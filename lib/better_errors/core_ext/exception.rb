module BetterErrors
  module CoreExt
    module Exception
      def set_backtrace(*)
        unless Thread.current[:__better_errors_exception_lock]
          Thread.current[:__better_errors_exception_lock] = true
          begin
            @__better_errors_bindings_stack = binding.callers.drop(1)
          ensure
            Thread.current[:__better_errors_exception_lock] = false
          end
        end

        super
      end

      def __better_errors_bindings_stack
        @__better_errors_bindings_stack || []
      end
    end
  end
end

Exception.send(:prepend, BetterErrors::CoreExt::Exception)
