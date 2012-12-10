require "fiber"
require "pry"

module BetterErrors
  module REPL
    class Pry
      class Input
        def initialize(fiber)
          @fiber = fiber
        end
        
        def readline(*args)
          Fiber.yield
        end
      end
      
      class Output
        def initialize
          @buffer = ""
        end
        
        def puts(*args)
          args.each do |arg|
            @buffer << "#{arg.chomp}\n"
          end
        end
        
        def tty?
          false
        end
        
        def read_buffer
          @buffer.tap do
            @buffer = ""
          end
        end
      end
      
      def initialize(binding)
        @binding = binding
        @fiber = Fiber.new do
          @pry.repl @binding
        end
        @input = Input.new @fiber
        @output = Output.new
        @pry = ::Pry.new input: @input, output: @output
        @pry.hooks.clear_all
        @continued_expression = false
        @pry.hooks.add_hook :after_read, "better_errors hacky hook" do
          @continued_expression = false
        end
        @fiber.resume
      end
      
      def pry_indent
        @pry.instance_variable_get(:@indent)
      end
    
      def send_input(str)
        old_pry_config_color = ::Pry.config.color
        ::Pry.config.color = false
        @continued_expression = true
        @fiber.resume "#{str}\n"
        # TODO - indent with `pry_indent.current_prefix`
        # TODO - use proper pry prompt
        [@output.read_buffer, @continued_expression ? ".." : ">>"]
      ensure
        ::Pry.config.color = old_pry_config_color
      end
    end
  end
end
