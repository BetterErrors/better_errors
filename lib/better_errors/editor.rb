require "uri"

module BetterErrors
  module Editor
    KNOWN_EDITORS = [
      { symbols: [:atom], sniff: /atom/i, url: "atom://core/open/file?filename=%{file}&line=%{line}" },
      { symbols: [:emacs, :emacsclient], sniff: /emacs/i, url: "emacs://open?url=file://%{file}&line=%{line}" },
      { symbols: [:idea], sniff: /idea/i, url: "idea://open?file=%{file}&line=%{line}" },
      { symbols: [:macvim, :mvim], sniff: /vim/i, url: "mvim://open?url=file://%{file_unencoded}&line=%{line}" },
      { symbols: [:rubymine], sniff: /mine/i, url: "x-mine://open?file=%{file}&line=%{line}" },
      { symbols: [:sublime, :subl, :st], sniff: /subl/i, url: "subl://open?url=file://%{file}&line=%{line}" },
      { symbols: [:textmate, :txmt, :tm], sniff: /mate/i, url: "txmt://open?url=file://%{file}&line=%{line}" },
      { symbols: [:vscode, :code], sniff: /code/i, url: "vscode://file/%{file}:%{line}" },
      { symbols: [:vscodium, :codium], sniff: /codium/i, url: "vscodium://file/%{file}:%{line}" },
    ]

    class UsingFormattingString
      def initialize(url_formatting_string)
        @url_formatting_string = url_formatting_string
      end

      def url(file, line)
        url_formatting_string % { file: URI.encode_www_form_component(file), file_unencoded: file, line: line }
      end

      private

      attr_reader :url_formatting_string
    end

    class UsingProc
      def initialize(url_proc)
        @url_proc = url_proc
      end

      def url(file, line)
        url_proc.call(file, line)
      end

      private

      attr_reader :url_proc
    end

    def self.for_formatting_string(formatting_string)
      UsingFormattingString.new(formatting_string)
    end

    def self.for_proc(url_proc)
      UsingProc.new(url_proc)
    end

    def self.for_symbol(symbol)
      KNOWN_EDITORS.each do |preset|
        return for_formatting_string(preset[:url]) if preset[:symbols].include?(symbol)
      end
    end

    # Automatically sniffs a default editor preset based on
    # environment variables.
    #
    # @return [Symbol]
    def self.default_editor
      editor_from_environment_formatting_string ||
        editor_from_environment_editor ||
        for_symbol(:textmate)
    end

    def self.editor_from_environment_editor
      if ENV["BETTER_ERRORS_EDITOR"]
        editor = editor_from_command(ENV["BETTER_ERRORS_EDITOR"])
        return editor if editor
        puts "BETTER_ERRORS_EDITOR environment variable is not recognized as a supported Better Errors editor."
      end
      if ENV["EDITOR"]
        editor = editor_from_command(ENV["EDITOR"])
        return editor if editor
        puts "EDITOR environment variable is not recognized as a supported Better Errors editor. Using TextMate by default."
      else
        puts "Since there is no EDITOR or BETTER_ERRORS_EDITOR environment variable, using Textmate by default."
      end
    end

    def self.editor_from_command(editor_command)
      env_preset = KNOWN_EDITORS.find { |preset| editor_command =~ preset[:sniff] }
      for_formatting_string(env_preset[:url]) if env_preset
    end

    def self.editor_from_environment_formatting_string
      return unless ENV['BETTER_ERRORS_EDITOR_URL']

      for_formatting_string(ENV['BETTER_ERRORS_EDITOR_URL'])
    end
  end
end
