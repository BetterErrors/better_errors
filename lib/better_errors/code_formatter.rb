module BetterErrors
  # @private
  class CodeFormatter
    FILE_TYPES = {
      ".rb"   => :ruby,
      ""      => :ruby,
      ".html" => :html,
      ".erb"  => :erb,
      ".haml" => :haml
    }
    
    attr_reader :filename, :line, :context
    
    def initialize(filename, line, context = 5)
      @filename = filename
      @line     = line
      @context  = context
    end
    
    def html
      %{<div class="code">#{formatted_lines.join}</div>}
    rescue Errno::ENOENT, Errno::EINVAL
      source_unavailable
    end
    
    def source_unavailable
      "<p class='unavailable'>Source unavailable</p>"
    end
    
    def coderay_scanner
      ext = File.extname(filename)
      FILE_TYPES[ext] || :text
    end
    
    def formatted_lines
      line_range.zip(highlighted_lines).map do |current_line, str|
        class_name = current_line == line ? "highlight" : ""
        sprintf '<pre class="%s">%5d %s</pre>', class_name, current_line, str
      end
    end
    
    def highlighted_lines
      CodeRay.scan(context_lines.join, coderay_scanner).div(wrap: nil).lines
    end
    
    def context_lines
      range = line_range
      source_lines[(range.begin - 1)..(range.end - 1)] or raise Errno::EINVAL
    end
    
    def source_lines
      @source_lines ||= File.readlines(filename)
    end
    
    def line_range
      min = [line - context, 1].max
      max = [line + context, source_lines.count].min
      min..max
    end
  end
end
