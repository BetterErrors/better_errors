module BetterErrors
  # @private
  class CodeFormatter
    require "better_errors/code_formatter/html"
    require "better_errors/code_formatter/text"

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

    def output
      formatted_code
    rescue Errno::ENOENT, Errno::EINVAL
      source_unavailable
    end

    def formatted_code
      formatted_lines.join
    end

    def coderay_scanner
      ext = File.extname(filename)
      FILE_TYPES[ext] || :text
    end

    def each_line_of(lines, &blk)
      line_range.zip(lines).map { |current_line, str|
        yield (current_line == line), current_line, str
      }
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
