require "spec_helper"

RSpec.describe BetterErrors::Editor do
  describe ".for_formatting_string" do
    it "returns an object that reponds to #url" do
      editor = described_class.for_formatting_string("custom://%{file}:%{file_unencoded}:%{line}")
      expect(editor.url("/path&file", 42)).to eq("custom://%2Fpath%26file:/path&file:42")
    end
  end

  describe ".for_proc" do
    it "returns an object that responds to #url, which calls the proc" do
      editor = described_class.for_proc(proc { |file, line| "result" } )
      expect(editor.url("foo", 42)).to eq("result")
    end
  end

  describe ".for_symbol" do
    subject { described_class.for_symbol(symbol) }

    [:atom].each do |symbol|
      context "when symbol is '#{symbol}'" do
        let(:symbol) { symbol }

        it "uses atom:// scheme" do
          expect(subject.url("file", 42)).to start_with("atom://")
        end
      end
    end

    [:emacs, :emacsclient].each do |symbol|
      context "when symbol is '#{symbol}'" do
        let(:symbol) { symbol }
        it "uses emacs:// scheme" do
          expect(subject.url("file", 42)).to start_with("emacs://")
        end
      end
    end

    [:macvim, :mvim].each do |symbol|
      context "when symbol is '#{symbol}'" do
        let(:symbol) { symbol }

        it "uses mvim:// scheme" do
          expect(subject.url("file", 42)).to start_with("mvim://")
        end
      end
    end

    [:sublime, :subl, :st].each do |symbol|
      context "when symbol is '#{symbol}'" do
        let(:symbol) { symbol }

        it "uses subl:// scheme" do
          expect(subject.url("file", 42)).to start_with("subl://")
        end
      end
    end

    [:textmate, :txmt, :tm].each do |symbol|
      context "when symbol is '#{symbol}'" do
        let(:symbol) { symbol }

        it "uses txmt:// scheme" do
          expect(subject.url("file", 42)).to start_with("txmt://")
        end
      end
    end
  end

  describe ".default_editor" do
    subject(:default_editor) { described_class.default_editor }
    before do
      ENV['BETTER_ERRORS_EDITOR_URL'] = nil
      ENV['BETTER_ERRORS_EDITOR'] = nil
      ENV['EDITOR'] = nil
    end

    it "returns an object that responds to #url" do
        expect(default_editor.url("foo", 123)).to match(/foo/)
    end

    context "when $BETTER_ERRORS_EDITOR_URL is set" do
      before do
        ENV['BETTER_ERRORS_EDITOR_URL'] = "custom://%{file}:%{file_unencoded}:%{line}"
      end

      it "uses the value as a formatting string to build the editor URL" do
        expect(default_editor.url("/path&file", 42)).to eq("custom://%2Fpath%26file:/path&file:42")
      end
    end

    context "when $BETTER_ERRORS_EDITOR is set to one of the preset commands" do
      before do
        ENV['BETTER_ERRORS_EDITOR'] = "subl"
      end

      it "returns an object that builds URLs for the corresponding editor" do
        expect(default_editor.url("foo", 123)).to start_with('subl://')
      end
    end

    context "when $EDITOR is set to one of the preset commands" do
      before do
        ENV['EDITOR'] = "subl"
      end

      it "returns an object that builds URLs for the corresponding editor" do
        expect(default_editor.url("foo", 123)).to start_with('subl://')
      end

      context "when $BETTER_ERRORS_EDITOR is set to one of the preset commands" do
        before do
          ENV['BETTER_ERRORS_EDITOR'] = "emacs"
        end

        it "returns an object that builds URLs for that editor instead" do
          expect(default_editor.url("foo", 123)).to start_with('emacs://')
        end
      end

      context "when $BETTER_ERRORS_EDITOR is set to an unrecognized command" do
        before do
          ENV['BETTER_ERRORS_EDITOR'] = "fubarcmd"
        end

        it "returns an object that builds URLs for the $EDITOR instead" do
          expect(default_editor.url("foo", 123)).to start_with('subl://')
        end
      end
    end

    context "when $EDITOR is set to an unrecognized command" do
      before do
        ENV['EDITOR'] = "fubarcmd"
      end

      it "returns an object that builds URLs for TextMate" do
        expect(default_editor.url("foo", 123)).to start_with('txmt://')
      end
    end

    context "when $EDITOR and $BETTER_ERRORS_EDITOR are not set" do
      it "returns an object that builds URLs for TextMate" do
        expect(default_editor.url("foo", 123)).to start_with('txmt://')
      end
    end
  end

  describe ".editor_from_command" do
    subject { described_class.editor_from_command(command_line) }

    ["atom -w", "/usr/bin/atom -w"].each do |command|
      context "when editor command is '#{command}'" do
        let(:command_line) { command }

        it "uses atom:// scheme" do
          expect(subject.url("file", 42)).to start_with("atom://")
        end
      end
    end

    ["emacsclient", "/usr/local/bin/emacsclient"].each do |command|
      context "when editor command is '#{command}'" do
        let(:command_line) { command }

        it "uses emacs:// scheme" do
          expect(subject.url("file", 42)).to start_with("emacs://")
        end
      end
    end

    ["idea"].each do |command|
      context "when editor command is '#{command}'" do
        let(:command_line) { command }

        it "uses idea:// scheme" do
          expect(subject.url("file", 42)).to start_with("idea://")
        end
      end
    end

    ["mate -w", "/usr/bin/mate -w"].each do |command|
      context "when editor command is '#{command}'" do
        let(:command_line) { command }

        it "uses txmt:// scheme" do
          expect(subject.url("file", 42)).to start_with("txmt://")
        end
      end
    end

    ["mine"].each do |command|
      context "when editor command is '#{command}'" do
        let(:command_line) { command }

        it "uses x-mine:// scheme" do
          expect(subject.url("file", 42)).to start_with("x-mine://")
        end
      end
    end

    ["mvim -f", "/usr/local/bin/mvim -f"].each do |command|
      context "when editor command is '#{command}'" do
        let(:command_line) { command }

        it "uses mvim:// scheme" do
          expect(subject.url("file", 42)).to start_with("mvim://")
        end
      end
    end

    ["subl -w", "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl"].each do |command|
      context "when editor command is '#{command}'" do
        let(:command_line) { command }

        it "uses subl:// scheme" do
          expect(subject.url("file", 42)).to start_with("subl://")
        end
      end
    end

    ["vscode", "code"].each do |command|
      context "when editor command is '#{command}'" do
        let(:command_line) { command }

        it "uses vscode:// scheme" do
          expect(subject.url("file", 42)).to start_with("vscode://")
        end
      end
    end
  end
end
