require "json"

module BetterErrors
  class ErrorPage
    def self.template_path(template_name)
      File.expand_path("../templates/#{template_name}.erb", __FILE__)
    end
    
    def self.template(template_name)
      Erubis::EscapedEruby.new(File.read(template_path(template_name)))
    end
    
    attr_reader :exception, :env, :repls
    
    def initialize(exception, env)
      @exception = real_exception(exception)
      @env = env
      @start_time = Time.now.to_f
      @repls = []
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
      code = opts["source"]
      
      unless binding = backtrace_frames[index].frame_binding
        return { error: "REPL unavailable in this stack frame" }
      end
      
      result, prompt =
        (@repls[index] ||= REPL.provider.new(binding)).send_input(code)
      
      { result: result,
        prompt: prompt,
        highlighted_input: CodeRay.scan(code, :ruby).div(wrap: nil) }
    end

    def backtrace_frames
      @backtrace_frames ||= StackFrame.from_exception(exception)
    end
    
  private
    def exception_message
      if exception.is_a?(SyntaxError) && exception.message =~ /\A.*:\d*: (.*)$/
        $1
      else
        exception.message
      end
    end

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
    
    def highlighted_code_block(frame)
      CodeFormatter.new(frame.filename, frame.line).html
    end
  end
end
