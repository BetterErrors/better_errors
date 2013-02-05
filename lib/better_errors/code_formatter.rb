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
      %{<div class="code">#{html_formatted_lines.join}</div>}
    rescue Errno::ENOENT, Errno::EINVAL
      html_source_unavailable
    end

    def text
      text_formatted_lines.join
    rescue Errno::ENOENT, Errno::EINVAL
      text_source_unavailable
    end
    
    def html_source_unavailable
      "<p class='unavailable'>Source is not available</p>"
    end
    
    def text_source_unavailable
      "# Source is not available"
    end
    
    def coderay_scanner
      ext = File.extname(filename)
      FILE_TYPES[ext] || :text
    end
    
    def html_formatted_lines
      each_line_of highlighted_lines do |highlight, current_line, str|
        class_name = highlight ? "highlight" : ""
        sprintf '<pre class="%s">%5d %s</pre>', class_name, current_line, str
      end
    end

    def text_formatted_lines
      each_line_of context_lines do |highlight, current_line, str|
        sprintf '%s %3d   %s', (highlight ? '>' : ' '), current_line, str
      end
    end

    def each_line_of(lines, &blk)
      line_range.zip(lines).map do |current_line, str|
        yield (current_line == line), current_line, str
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
