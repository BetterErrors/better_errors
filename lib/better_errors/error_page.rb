require "cgi"
require "json"

module BetterErrors
  # @private
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
      @var_start_time = Time.now.to_f
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

    def application_frames
      backtrace_frames.select { |frame| frame.context == :application }
    end

    def first_frame
      backtrace_frames.detect { |frame| frame.context == :application } || backtrace_frames.first
    end
    
  private
    def editor_url(frame)
      BetterErrors.editor[frame.filename, frame.line]
    end
    
    def rack_session
      env['rack.session']
    end

    def rails_params
      env['action_dispatch.request.parameters']
    end

    def uri_prefix
      env["SCRIPT_NAME"] || ""
    end
  
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
      env["PATH_INFO"]
    end
    
    def highlighted_code_block(frame, format=:html)
      CodeFormatter.new(frame.filename, frame.line).send format
    end

    def text_heading(char, str)
      str + "\n" + char*str.size
    end

    def escape_value(value)
      CGI.escapeHTML(value)
    end

    def inspect_value(obj)
      escape_value(obj.inspect)
    rescue NoMethodError
      "<span class='unsupported'>(object doesn't support inspect)</span>"
    rescue Exception
      "<span class='unsupported'>(exception was raised in inspect)</span>"
    end

    def pretty_hash_json(object)
      escape_value(JSON.pretty_generate(purify_hash(object)))
    end

    # Converts a hash-like object to a real hashes.
    #
    # Required, e.g., for generating pretty JSON for a HashWithIndifferentAccess object, because some versions of JSON
    # fail to pretty print objects that are instances of Hash subclasses and not of Hash class itself.
    #
    def purify_hash(object)
      if object.is_a?(Hash) && !object.instance_of?(Hash)
        object.each_with_object({}) do |(key, value), memo|
          memo[key] = purify_hash(value)
        end
      else
        object
      end
    end
  end
end
