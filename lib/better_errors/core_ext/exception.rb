class Exception
  attr_reader :__better_errors_bindings_stack
  
  original_initialize = instance_method(:initialize)
  
  define_method :initialize do |*args|
    unless Thread.current[:__better_errors_exception_lock]
      Thread.current[:__better_errors_exception_lock] = true
      begin
        @__better_errors_bindings_stack = []
        2.upto(caller.size) do |index|
          @__better_errors_bindings_stack << binding.of_caller(index) rescue break
        end
      ensure
        Thread.current[:__better_errors_exception_lock] = false
      end
    end
    original_initialize.bind(self).call(*args)
  end
end