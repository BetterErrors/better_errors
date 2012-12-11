module BetterErrors
  class StackFrame
    def self.from_exception(exception)
      idx_offset = 0
      list = exception.backtrace.each_with_index.map do |frame, idx|
        frame_binding = exception.__better_errors_bindings_stack[idx - idx_offset]
        md = /\A(?<file>.*):(?<line>\d*)(:in `(?<name>.*)')?\z/.match(frame)

        # prevent mismatching frames in the backtrace with the binding stack
        if frame_binding and frame_binding.eval("__FILE__") != md[:file]
          idx_offset += 1
          frame_binding = nil
        end

        StackFrame.new(md[:file], md[:line].to_i, md[:name], frame_binding)
      end

      if exception.is_a?(SyntaxError) && exception.to_s =~ /\A(.*):(\d*):/
        list.unshift StackFrame.new($1, $2.to_i, "")
      end

      list
    end
    
    attr_reader :filename, :line, :name, :frame_binding
    
    def initialize(filename, line, name, frame_binding = nil)
      @filename       = filename
      @line           = line
      @name           = name
      @frame_binding  = frame_binding
      
      set_pretty_method_name if frame_binding
    end
    
    def application?
      root = BetterErrors.application_root
      starts_with? filename, root if root
    end
    
    def application_path
      filename[(BetterErrors.application_root.length+1)..-1]
    end

    def gem?
      Gem.path.any? { |path| starts_with? filename, path }
    end
    
    def gem_path
      Gem.path.each do |path|
        if starts_with? filename, path
          return filename.gsub("#{path}/gems/", "(gem) ")
        end
      end
    end

    def class_name
      @class_name
    end

    def method_name
      @method_name || @name
    end
    
    def context
      if application?
        :application
      elsif gem?
        :gem
      else
        :dunno
      end
    end
    
    def pretty_path
      case context
      when :application;  application_path
      when :gem;          gem_path
      else                filename
      end
    end
    
    def local_variables
      return {} unless frame_binding
      frame_binding.eval("local_variables").each_with_object({}) do |name, hash|
        begin
          hash[name] = frame_binding.eval(name.to_s)
        rescue NameError => e
          # local_variables sometimes returns broken variables.
          # https://bugs.ruby-lang.org/issues/7536
        end
      end
    end
    
    def instance_variables
      return {} unless frame_binding
      Hash[frame_binding.eval("instance_variables").map { |x|
        [x, frame_binding.eval(x.to_s)]
      }]
    end
    
    def to_s
      "#{pretty_path}:#{line}:in `#{name}'"
    end
    
  private
    def set_pretty_method_name
      name =~ /\A(block (\([^)]+\) )?in )?/
      recv = frame_binding.eval("self")
      return unless method_name = frame_binding.eval("__method__")
      if recv.is_a? Module
        @class_name = "#{$1}#{recv}"
        @method_name = ".#{method_name}"
      else
        @class_name = "#{$1}#{recv.class}"
        @method_name = "##{method_name}"
      end
    end
  
    def starts_with?(haystack, needle)
      haystack[0, needle.length] == needle
    end
  end
end
