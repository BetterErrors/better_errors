require "fiber"
require "pry"

module BetterErrors
  module REPL
    class Pry
      class Input
        def readline
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
          @buffer
        ensure
          @buffer = ""
        end
      end
      
      def initialize(binding)
        @fiber = Fiber.new do
          @pry.repl binding
        end
        @input = Input.new
        @output = Output.new
        @pry = ::Pry.new input: @input, output: @output
        @pry.hooks.clear_all
        @continued_expression = false
        @pry.hooks.add_hook :after_read, "better_errors hacky hook" do
          @continued_expression = false
        end
        @fiber.resume
      end
    
      def send_input(str)
        local ::Pry.config, color: false, pager: false do
          @continued_expression = true
          @fiber.resume "#{str}\n"
          [@output.read_buffer, @continued_expression ? ".." : ">>"]
        end
      end
      
    private
      def local(obj, attrs)
        old_attrs = {}
        attrs.each do |k, v|
          old_attrs[k] = obj.send k
          obj.send "#{k}=", v
        end
        yield
      ensure
        old_attrs.each do |k, v|
          obj.send "#{k}=", v
        end
      end
    end
  end
end
