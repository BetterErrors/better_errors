require "cgi"
require "json"
require "securerandom"

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
      @exception = RaisedException.new(exception)
      @env = env
      @start_time = Time.now.to_f
      @repls = []
    end

    def id
      @id ||= SecureRandom.hex(8)
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

      unless (binding = backtrace_frames[index].frame_binding)
        return { error: "REPL unavailable in this stack frame" }
      end

      @repls[index] ||= get_repl(index, binding)

      send_input(index, code)
    end

    def backtrace_frames
      exception.backtrace
    end

    def exception_type
      exception.type
    end

    def exception_message
      exception.message.lstrip
    end

    def application_frames
      backtrace_frames.select(&:application?)
    end

    def first_frame
      application_frames.first || backtrace_frames.first
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

    def request_path
      env["PATH_INFO"]
    end

    def html_formatted_code_block(frame)
      CodeFormatter::HTML.new(frame.filename, frame.line).output
    end

    def text_formatted_code_block(frame)
      CodeFormatter::Text.new(frame.filename, frame.line).output
    end

    def text_heading(char, str)
      str + "\n" + char*str.size
    end

    def inspect_value(obj)
      CGI.escapeHTML(obj.inspect)
    rescue NoMethodError
      "<span class='unsupported'>(object doesn't support inspect)</span>"
    rescue Exception
      "<span class='unsupported'>(exception was raised in inspect)</span>"
    end

    def get_repl(index, binding)
      REPL.provider.new(binding).tap do |repl|
        if repl.is_a?(REPL::Pry)
          pry = repl.instance_variable_get(:@pry)
          pry.instance_variable_set(
            :@last_exception,
            ::Pry::LastException.new(@exception.exception)
          )
        end
      end
    end

    def send_input(index, code)
      result, prompt, prefilled_input = @repls[index].send_input(code)

      {
        highlighted_input: CodeRay.scan(code, :ruby).div(wrap: nil),
        prefilled_input:   prefilled_input,
        prompt:            prompt,
        result:            result
      }
    end
  end
end
