require "securerandom"

module BetterErrors
  ##
  # When an exception has been rescued by Better Errors, this object is used to store it, provide information
  # about it, and cache things used to access it, like REPL instances.
  # @private
  class ErrorState
    def initialize(whole_exception, env)
      @whole_exception = RaisedException.new(whole_exception)
      @env = env
      @repls = []
    end

    def id
      @id ||= SecureRandom.hex(8)
    end

    attr_reader :whole_exception

    def cached_repl_for(index)
      @repls[index] ||= yield
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

    private

    attr_reader :env
  end
end
