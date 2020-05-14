require "cgi"
require "json"

module BetterErrors
  # @private
  class ErrorPage
    def self.template_path(template_name)
      File.expand_path("../templates/#{template_name}.erb", __FILE__)
    end

    def self.template(template_name)
      Erubi::Engine.new(File.read(template_path(template_name)), escape: true)
    end

    def initialize(error_state, env)
      @error_state = error_state
      @env = env
      @start_time = Time.now.to_f
    end

    def render(template_name = "main")
      binding.eval(self.class.template(template_name).src)
    rescue => e
      # Fix the backtrace, which doesn't identify the template that failed (within Better Errors).
      # We don't know the line number, so just injecting the template path has to be enough.
      e.backtrace.unshift "#{self.class.template_path(template_name)}:0"
      raise
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

      repl = error_state.cached_repl_for(index) { REPL.provider.new(binding, exception) }

      eval_and_respond(repl, code)
    end

    private

    attr_reader :error_state
    attr_reader :env

    def exception
      error_state.whole_exception
    end

    def exception_id
      error_state.id
    end

    def exception_type
      exception.type
    end

    def exception_message
      exception.message
    end

    def backtrace_frames
      exception.backtrace
    end

    def active_support_actions
      exception.active_support_actions
    end

    def action_dispatch_action_endpoint
      return unless defined?(ActionDispatch::ActionableExceptions)

      ActionDispatch::ActionableExceptions.endpoint
    end

    def application_frames
      backtrace_frames.select(&:application?)
    end

    def first_frame
      application_frames.first || backtrace_frames.first
    end

    def editor_url(frame)
      BetterErrors.editor[frame.filename, frame.line]
    end

    def rack_session
      error_state.rack_session
    end

    def rails_params
      error_state.rails_params
    end

    def uri_prefix
      error_state.uri_prefix
    end

    def request_path
      error_state.request_path
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
      if BetterErrors.ignored_classes.include? obj.class.name
        "<span class='unsupported'>(Instance of ignored class. "\
        "#{obj.class.name ? "Remove #{CGI.escapeHTML(obj.class.name)} from" : "Modify"}"\
        " BetterErrors.ignored_classes if you need to see it.)</span>"
      else
        InspectableValue.new(obj).to_html
      end
    rescue BetterErrors::ValueLargerThanConfiguredMaximum
      "<span class='unsupported'>(Object too large. "\
        "#{obj.class.name ? "Modify #{CGI.escapeHTML(obj.class.name)}#inspect or a" : "A"}"\
        "djust BetterErrors.maximum_variable_inspect_size if you need to see it.)</span>"
    rescue Exception => e
      "<span class='unsupported'>(exception #{CGI.escapeHTML(e.class.to_s)} was raised in inspect)</span>"
    end

    def eval_and_respond(repl, code)
      result, prompt, prefilled_input = repl.send_input(code)

      {
        highlighted_input: CodeRay.scan(code, :ruby).div(wrap: nil),
        prefilled_input:   prefilled_input,
        prompt:            prompt,
        result:            result
      }
    end
  end
end
