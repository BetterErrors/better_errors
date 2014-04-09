require "spec_helper"

describe BetterErrors do
  context ".editor" do
    it "defaults to textmate" do
      subject.editors.first["foo.rb", 123].should == "txmt://open?url=file://foo.rb&line=123"
    end

    it "url escapes the filename" do
      subject.editors.first["&.rb", 0].should == "txmt://open?url=file://%26.rb&line=0"
    end

    [:emacs, :emacsclient].each do |editor|
      it "uses emacs:// scheme when set to #{editor.inspect}" do
        subject.editor = editor
        subject.editors.first[].should start_with "emacs://"
      end
    end

    [:macvim, :mvim].each do |editor|
      it "uses mvim:// scheme when set to #{editor.inspect}" do
        subject.editor = editor
        subject.editors.first[].should start_with "mvim://"
      end
    end

    [:sublime, :subl, :st].each do |editor|
      it "uses subl:// scheme when set to #{editor.inspect}" do
        subject.editor = editor
        subject.editors.first[].should start_with "subl://"
      end
    end

    [:textmate, :txmt, :tm].each do |editor|
      it "uses txmt:// scheme when set to #{editor.inspect}" do
        subject.editor = editor
        subject.editors.first[].should start_with "txmt://"
      end
    end

    ["emacsclient", "/usr/local/bin/emacsclient"].each do |editor|
      it "uses emacs:// scheme when EDITOR=#{editor}" do
        ENV["EDITOR"] = editor
        subject.editor = subject.default_editor
        subject.editors.first[].should start_with "emacs://"
      end
    end

    ["mvim -f", "/usr/local/bin/mvim -f"].each do |editor|
      it "uses mvim:// scheme when EDITOR=#{editor}" do
        ENV["EDITOR"] = editor
        subject.editor = subject.default_editor
        subject.editors.first[].should start_with "mvim://"
      end
    end

    ["subl -w", "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl"].each do |editor|
      it "uses subl:// scheme when EDITOR=#{editor}" do
        ENV["EDITOR"] = editor
        subject.editor = subject.default_editor
        subject.editors.first[].should start_with "subl://"
      end
    end

    ["mate -w", "/usr/bin/mate -w"].each do |editor|
      it "uses txmt:// scheme when EDITOR=#{editor}" do
        ENV["EDITOR"] = editor
        subject.editor = subject.default_editor
        subject.editors.first[].should start_with "txmt://"
      end
    end

    it "returns multiple URLs when set to a collection of editors" do
      subject.editors = [:macvim, "emacs://open?url=file://%{file}&line=%{line}", Proc.new { |file, line| "subl://open?url=file://%{file}&line=%{line}" }]
      subject.editors[0][].should start_with "mvim://"
      subject.editors[1][].should start_with "emacs://"
      subject.editors[2][].should start_with "subl://"
    end
  end
end
