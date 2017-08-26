require "pp"
require "erubi"
require "coderay"
require "uri"

require "better_errors/code_formatter"
require "better_errors/error_page"
require "better_errors/middleware"
require "better_errors/raised_exception"
require "better_errors/repl"
require "better_errors/stack_frame"
require "better_errors/version"

module BetterErrors
  POSSIBLE_EDITOR_PRESETS = [
    { symbols: [:emacs, :emacsclient],  sniff: /emacs/i, url: "emacs://open?url=file://%{file}&line=%{line}" },
    { symbols: [:macvim, :mvim],        sniff: /vim/i,   url: proc { |file, line| "mvim://open?url=file://#{file}&line=#{line}" } },
    { symbols: [:sublime, :subl, :st],  sniff: /subl/i,  url: "subl://open?url=file://%{file}&line=%{line}" },
    { symbols: [:textmate, :txmt, :tm], sniff: /mate/i,  url: "txmt://open?url=file://%{file}&line=%{line}" },
    { symbols: [:idea], sniff: /idea/i, url: "idea://open?file=%{file}&line=%{line}" },
    { symbols: [:rubymine], sniff: /mine/i, url: "x-mine://open?file=%{file}&line=%{line}" },
  ]

  class << self
    # The path to the root of the application. Better Errors uses this property
    # to determine if a file in a backtrace should be considered an application
    # frame. If you are using Better Errors with Rails, you do not need to set
    # this attribute manually.
    #
    # @return [String]
    attr_accessor :application_root

    # The logger to use when logging exception details and backtraces. If you
    # are using Better Errors with Rails, you do not need to set this attribute
    # manually. If this attribute is `nil`, nothing will be logged.
    #
    # @return [Logger, nil]
    attr_accessor :logger

    # @private
    attr_accessor :binding_of_caller_available

    # @private
    alias_method :binding_of_caller_available?, :binding_of_caller_available

    # The ignored instance variables.
    # @return [Array]
    attr_accessor :ignored_instance_variables

    # The maximum variable payload size. If variable.inspect exceeds this,
    # the variable won't be returned.
    # @return int
    attr_accessor :maximum_variable_inspect_size
  end
  @ignored_instance_variables = []
  @maximum_variable_inspect_size = 100_000

  # Returns a proc, which when called with a filename and line number argument,
  # returns a URL to open the filename and line in the selected editor.
  #
  # Generates TextMate URLs by default.
  #
  #   BetterErrors.editor["/some/file", 123]
  #     # => txmt://open?url=file:///some/file&line=123
  #
  # @return [Proc]
  def self.editor
    @editor
  end

  # Configures how Better Errors generates open-in-editor URLs.
  #
  # @overload BetterErrors.editor=(sym)
  #   Uses one of the preset editor configurations. Valid symbols are:
  #
  #   * `:textmate`, `:txmt`, `:tm`
  #   * `:sublime`, `:subl`, `:st`
  #   * `:macvim`
  #
  #   @param [Symbol] sym
  #
  # @overload BetterErrors.editor=(str)
  #   Uses `str` as the format string for generating open-in-editor URLs.
  #
  #   Use `%{file}` and `%{line}` as placeholders for the actual values.
  #
  #   @example
  #     BetterErrors.editor = "my-editor://open?url=%{file}&line=%{line}"
  #
  #   @param [String] str
  #
  # @overload BetterErrors.editor=(proc)
  #   Uses `proc` to generate open-in-editor URLs. The proc will be called
  #   with `file` and `line` parameters when a URL needs to be generated.
  #
  #   Your proc should take care to escape `file` appropriately with
  #   `URI.encode_www_form_component` (please note that `URI.escape` is **not**
  #   a suitable substitute.)
  #
  #   @example
  #     BetterErrors.editor = proc { |file, line|
  #       "my-editor://open?url=#{URI.encode_www_form_component file}&line=#{line}"
  #     }
  #
  #   @param [Proc] proc
  #
  def self.editor=(editor)
    POSSIBLE_EDITOR_PRESETS.each do |config|
      if config[:symbols].include?(editor)
        return self.editor = config[:url]
      end
    end

    if editor.is_a? String
      self.editor = proc { |file, line| editor % { file: URI.encode_www_form_component(file), line: line } }
    else
      if editor.respond_to? :call
        @editor = editor
      else
        raise TypeError, "Expected editor to be a valid editor key, a format string or a callable."
      end
    end
  end

  # Enables experimental Pry support in the inline REPL
  #
  # If you encounter problems while using Pry, *please* file a bug report at
  # https://github.com/charliesome/better_errors/issues
  def self.use_pry!
    REPL::PROVIDERS.unshift const: :Pry, impl: "better_errors/repl/pry"
  end

  # Automatically sniffs a default editor preset based on the EDITOR
  # environment variable.
  #
  # @return [Symbol]
  def self.default_editor
    POSSIBLE_EDITOR_PRESETS.detect(-> { {} }) { |config|
      ENV["EDITOR"] =~ config[:sniff]
    }[:url] || :textmate
  end

  BetterErrors.editor = default_editor
end

begin
  require "binding_of_caller"
  require "better_errors/exception_extension"
  BetterErrors.binding_of_caller_available = true
rescue LoadError
  BetterErrors.binding_of_caller_available = false
end

require "better_errors/rails" if defined? Rails::Railtie
