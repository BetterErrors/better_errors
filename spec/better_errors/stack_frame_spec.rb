require "spec_helper"

module BetterErrors
  describe StackFrame do
    context "#application?" do
      it "should be true for application filenames" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        
        frame.application?.should be_true
      end
      
      it "should be false for everything else" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/nope", 123, "foo")
        
        frame.application?.should be_false
      end
      
      it "should not care if no application_root is set" do
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        
        frame.application?.should be_false
      end
    end
    
    context "#gem?" do
      it "should be true for gem filenames" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")
        
        frame.gem?.should be_true
      end
      
      it "should be false for everything else" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/nope", 123, "foo")
        
        frame.gem?.should be_false
      end
    end
    
    context "#application_path" do
      it "should chop off the application root" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        
        frame.application_path.should == "app/controllers/crap_controller.rb"
      end
    end
    
    context "#gem_path" do
      it "should chop of the gem path and stick (gem) there" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")
        
        frame.gem_path.should == "(gem) whatever-1.2.3/lib/whatever.rb"
      end
    end

    it "should special case SyntaxErrors" do
      syntax_error = SyntaxError.new "my_file.rb:123: you wrote bad ruby!"
      syntax_error.stub!(:backtrace).and_return([])
      frames = StackFrame.from_exception(syntax_error)
      frames.count.should == 1
      frames.first.filename.should == "my_file.rb"
      frames.first.line.should == 123
    end

    it "has a Sublime path" do
      filename = "/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb"
      line = 123
      frame = StackFrame.new(filename, line, "_")
      frame.sublime_path.should eq("subl://open/?url=file://#{filename}&line=#{line}")
    end
  end
end
