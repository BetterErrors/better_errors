module BetterErrors
  class ErrorFrame
    def self.from_exception(exception)
      exception.backtrace.each_with_index.map { |frame, idx|
        next unless frame =~ /\A(.*):(\d*):in `(.*)'\z/
        ErrorFrame.new($1, $2.to_i, $3, exception.__better_errors_bindings_stack[idx])
      }.compact
    end
    
    attr_reader :filename, :line, :name, :frame_binding
    
    def initialize(filename, line, name, frame_binding)
      @filename       = filename
      @line           = line
      @name           = name
      @frame_binding  = frame_binding
    end
    
    def application?
      starts_with? filename, BetterErrors.application_root if BetterErrors.application_root
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
      Hash[frame_binding.eval("local_variables").map { |x| [x, frame_binding.eval(x.to_s)] }]
    end
    
    def instance_variables
      return {} unless frame_binding
      Hash[frame_binding.eval("instance_variables").map { |x| [x, frame_binding.eval(x.to_s)] }]
    end
    
  private
    def starts_with?(haystack, needle)
      haystack[0, needle.length] == needle
    end
  end
end
