require "set"

module BetterErrors
  # @private
  class StackFrame
    def self.from_exception(exception)
      RaisedException.new(exception).backtrace
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
      if root = BetterErrors.application_root
        filename.index(root) == 0 && filename.index("#{root}/vendor") != 0
      end
    end

    def application_path
      filename[(BetterErrors.application_root.length+1)..-1]
    end

    def gem?
      Gem.path.any? { |path| filename.index(path) == 0 }
    end

    def gem_path
      if path = Gem.path.detect { |path| filename.index(path) == 0 }
        gem_name_and_version, path = filename.sub("#{path}/gems/", "").split("/", 2)
        /(?<gem_name>.+)-(?<gem_version>[\w.]+)/ =~ gem_name_and_version
        "#{gem_name} (#{gem_version}) #{path}"
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
        if defined?(frame_binding.local_variable_get)
          hash[name] = frame_binding.local_variable_get(name)
        else
          hash[name] = frame_binding.eval(name.to_s)
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

      return unless method_name = frame_binding.eval("::Kernel.__method__")

      if Module === recv
        @class_name = "#{$1}#{recv}"
        @method_name = ".#{method_name}"
      else
        @class_name = "#{$1}#{Kernel.instance_method(:class).bind(recv).call}"
        @method_name = "##{method_name}"
      end
    end
  end
end
