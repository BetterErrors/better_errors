require "json"

module BetterErrors
  class ErrorPage
    def self.template_path(template_name)
      File.expand_path("../templates/#{template_name}.erb", __FILE__)
    end
    
    def self.template(template_name)
      Erubis::EscapedEruby.new(File.read(template_path(template_name)))
    end
    
    attr_reader :exception, :env
    
    def initialize(exception, env)
      @exception = real_exception(exception)
      @env = env
      @start_time = Time.now.to_f
    end
    
    def render(template_name = "main")
      self.class.template(template_name).result binding
    end
    
    def do_variables(opts)
      index = opts["index"].to_i
      @frame = backtrace_frames[index]
      { html: render("variable_info") }
    end
    
    def do_eval(opts)
      index = opts["index"].to_i
      binding = backtrace_frames[index].frame_binding
      return { error: "binding_of_caller unavailable" } unless binding
      response =  begin
                    result = binding.eval(opts["source"])
                    { result: result.inspect }
                  rescue Exception => e
                    { error: (e.inspect rescue e.class.name rescue "Exception") }
                  end
      response.merge(highlighted_input: CodeRay.scan(opts["source"], :ruby).div(wrap: nil))
    end

    def backtrace_frames
      @backtrace_frames ||= ErrorFrame.from_exception(exception)
    end
    
  private
    def real_exception(exception)
      if exception.respond_to? :original_exception
        exception.original_exception
      else
        exception
      end
    end
  
    def request_path
      env["REQUEST_PATH"]
    end
    
    def coderay_scanner_for_ext(ext)
      case ext
      when "rb";    :ruby
      when "html";  :html
      when "erb";   :erb
      when "haml";  :haml
      else          :text
      end
    end
    
    def file_extension(filename)
      filename.split(".").last
    end
    
    def code_extract(frame, lines_of_context = 5)
      lines = File.readlines(frame.filename)
      min_line = [1, frame.line - lines_of_context].max - 1
      max_line = [frame.line + lines_of_context, lines.count + 1].min - 1
      raise Errno::EINVAL if min_line > lines.length
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
    rescue Errno::ENOENT, Errno::EINVAL
      "<p>Source unavailable</p>"
    end
  end
end
