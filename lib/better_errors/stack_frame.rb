module BetterErrors
  # @private
  class StackFrame
    def self.from_exception(exception)
      if exception.__better_errors_bindings_stack.any?
        list = exception.__better_errors_bindings_stack.map { |binding|
          file = binding.eval "__FILE__"
          line = binding.eval "__LINE__"
          name = binding.frame_description
          StackFrame.new(file, line, name, binding)
        }
      else
        list = (exception.backtrace || []).map { |frame|
          next unless md = /\A(?<file>.*?):(?<line>\d+)(:in `(?<name>.*)')?/.match(frame)
          StackFrame.new(md[:file], md[:line].to_i, md[:name])
        }.compact
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
      filename.index(root) == 0 if root
    end
    
    def application_path
      filename[(BetterErrors.application_root.length+1)..-1]
    end

    def gem?
      Gem.path.any? { |path| filename.index(path) == 0 }
    end
    
    def gem_path
      Gem.path.each do |path|
        if filename.index(path) == 0
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
      if gem?
        :gem
      elsif application?
        :application
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
      Hash[visible_instance_variables.map { |x|
        [x, frame_binding.eval(x.to_s)]
      }]
    end

    def visible_instance_variables
      frame_binding.eval("instance_variables") - BetterErrors.ignored_instance_variables
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
  end
end
