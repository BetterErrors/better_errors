module BetterErrors
  # @private
  class CodeFormatter::HTML < CodeFormatter
    def source_unavailable
      "<p class='code-unavailable'>Source is not available</p>"
    end

    def formatted_lines
      each_line_of(highlighted_lines) { |highlight, current_line, str|
        class_name = highlight ? "highlight" : ""
        sprintf '<pre class="%s">%s</pre>', class_name, str
      }
    end

    def formatted_nums
      each_line_of(highlighted_lines) { |highlight, current_line, str|
        class_name = highlight ? "highlight" : ""
        sprintf '<pre class="%s">%4d</pre>', class_name, current_line
      }
    end

    def formatted_code
      %{<div class="code_linenums">#{formatted_nums.join}</div><div class="code">#{super}</div>}
    end
  end
end
