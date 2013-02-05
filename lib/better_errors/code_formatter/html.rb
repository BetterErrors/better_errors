module BetterErrors
  # @private
  class CodeFormatter::HTML < CodeFormatter
    def source_unavailable
      "<p class='unavailable'>Source is not available</p>"
    end

    def formatted_lines
      each_line_of highlighted_lines do |highlight, current_line, str|
        class_name = highlight ? "highlight" : ""
        sprintf '<pre class="%s">%5d %s</pre>', class_name, current_line, str
      end
    end

    def formatted_code
      %{<div class="code">#{super}</div>}
    end
  end
end
