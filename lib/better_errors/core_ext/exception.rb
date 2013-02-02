class Exception
  original_initialize = instance_method(:initialize)
  
  if BetterErrors.binding_of_caller_available?
    define_method :initialize do |*args|
      unless Thread.current[:__better_errors_exception_lock]
        Thread.current[:__better_errors_exception_lock] = true
        begin
          @__better_errors_bindings_stack = binding.callers.drop(1)
        ensure
          Thread.current[:__better_errors_exception_lock] = false
        end
      end
      original_initialize.bind(self).call(*args)
    end
  end
  
  def __better_errors_bindings_stack
    @__better_errors_bindings_stack || []
  end
end
