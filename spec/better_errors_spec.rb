require "spec_helper"

describe BetterErrors do
  context ".editor" do
    it "defaults to textmate" do
      expect(subject.editor["foo.rb", 123]).to eq("txmt://open?url=file://foo.rb&line=123")
    end

    it "url escapes the filename" do
      expect(subject.editor["&.rb", 0]).to eq("txmt://open?url=file://%26.rb&line=0")
    end

    [:emacs, :emacsclient].each do |editor|
      it "uses emacs:// scheme when set to #{editor.inspect}" do
        subject.editor = editor
        expect(subject.editor[]).to start_with "emacs://"
      end
    end

    [:macvim, :mvim].each do |editor|
      it "uses mvim:// scheme when set to #{editor.inspect}" do
        subject.editor = editor
        expect(subject.editor[]).to start_with "mvim://"
      end
    end

    [:sublime, :subl, :st].each do |editor|
      it "uses subl:// scheme when set to #{editor.inspect}" do
        subject.editor = editor
        expect(subject.editor[]).to start_with "subl://"
      end
    end

    [:textmate, :txmt, :tm].each do |editor|
      it "uses txmt:// scheme when set to #{editor.inspect}" do
        subject.editor = editor
        expect(subject.editor[]).to start_with "txmt://"
      end
    end

    ["emacsclient", "/usr/local/bin/emacsclient"].each do |editor|
      it "uses emacs:// scheme when EDITOR=#{editor}" do
        ENV["EDITOR"] = editor
        subject.editor = subject.default_editor
        expect(subject.editor[]).to start_with "emacs://"
      end
    end

    ["mvim -f", "/usr/local/bin/mvim -f"].each do |editor|
      it "uses mvim:// scheme when EDITOR=#{editor}" do
        ENV["EDITOR"] = editor
        subject.editor = subject.default_editor
        expect(subject.editor[]).to start_with "mvim://"
      end
    end

    ["subl -w", "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl"].each do |editor|
      it "uses subl:// scheme when EDITOR=#{editor}" do
        ENV["EDITOR"] = editor
        subject.editor = subject.default_editor
        expect(subject.editor[]).to start_with "subl://"
      end
    end

    ["mate -w", "/usr/bin/mate -w"].each do |editor|
      it "uses txmt:// scheme when EDITOR=#{editor}" do
        ENV["EDITOR"] = editor
        subject.editor = subject.default_editor
        expect(subject.editor[]).to start_with "txmt://"
      end
    end
  end
end
