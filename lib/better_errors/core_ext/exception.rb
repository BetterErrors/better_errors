class Exception
  hooked_methods = [:initialize, :set_backtrace]
  original_methods = {}
  
  if BetterErrors.binding_of_caller_available?
    hooked_methods.each do |method|
      original_methods[method] = instance_method(method)

      define_method method do |*args|
        unless Thread.current[:__better_errors_exception_lock] || @__better_errors_bindings_stack
          Thread.current[:__better_errors_exception_lock] = true
          begin
            @__better_errors_bindings_stack = binding.callers.drop(1)
          ensure
            Thread.current[:__better_errors_exception_lock] = false
          end
        end
        original_methods[method].bind(self).call(*args)
      end
    end
  end

  
  def __better_errors_bindings_stack
    @__better_errors_bindings_stack || []
  end
end
