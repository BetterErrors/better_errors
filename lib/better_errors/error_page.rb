require "json"

module BetterErrors
  class ErrorPage
    def self.template_path
      __FILE__.gsub(/\.rb$/, ".erb")
    end
    
    def self.template
      Erubis::EscapedEruby.new(File.read(template_path))
    end
    
    attr_reader :exception, :env
    
    def initialize(exception, env)
      @exception = real_exception(exception)
      @env = env
    end
    
    def render
      self.class.template.result binding
    end
    
  private
    def real_exception(exception)
      loop do
        case exception
        when ActionView::Template::Error; exception = exception.original_exception
        else
          return exception
        end
      end
    end
  
    def request_path
      env["REQUEST_PATH"]
    end
  
    def backtrace_frames
      @backtrace_frames ||= ErrorFrame.from_exception(exception)
    end
    
    def coderay_scanner_for_ext(ext)
      case ext
      when "rb";    :ruby
      when "html";  :html
      when "erb";   :erb
      when "haml";  :haml
      end
    end
    
    def file_extension(filename)
      filename.split(".").last
    end
    
    def code_extract(frame, lines_of_context = 5)
      lines = File.readlines(frame.filename)
      min_line = [1, frame.line - lines_of_context].max - 1
      max_line = [frame.line + lines_of_context, lines.count + 1].min - 1
      [min_line, max_line, lines[min_line..max_line].join]
    end
    
    def highlighted_code_block(frame)
      ext = file_extension(frame.filename)
      scanner = coderay_scanner_for_ext(ext)
      min_line, max_line, code = code_extract(frame)
      highlighted_code = CodeRay.scan(code, scanner).div wrap: nil
      "".tap do |html|
        html << "<div class='code'>"
        highlighted_code.each_line.each_with_index do |str, index|
          if min_line + index + 1 == frame.line
            html << "<pre class='highlight'>"
          else
            html << "<pre>"
          end
          html << sprintf("%5d", min_line + index + 1) << " " << str << "</pre>"
        end
        html << "</div>"
      end
    end
  end
end
