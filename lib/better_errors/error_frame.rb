module BetterErrors
  class ErrorFrame
    def self.from_exception(exception)
      exception.backtrace.each_with_index.map { |frame, idx|
        next unless frame =~ /\A(.*):(\d*):in `(.*)'\z/
        ErrorFrame.new($1, $2.to_i, $3)
      }.compact
    end
    
    attr_reader :filename, :line, :name
    
    def initialize(filename, line, name)
      @filename       = filename
      @line           = line
      @name           = name
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
    
  private
    def starts_with?(haystack, needle)
      haystack[0, needle.length] == needle
    end
  end
end
