require "spec_helper"

module BetterErrors
  describe StackFrame do
    context "#application?" do
      it "should be true for application filenames" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        
        expect(frame.application?).to be_true
      end
      
      it "should be false for everything else" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/nope", 123, "foo")
        
        expect(frame.application?).to be_false
      end
      
      it "should not care if no application_root is set" do
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        
        expect(frame.application?).to be_false
      end
    end
    
    context "#gem?" do
      it "should be true for gem filenames" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")
        
        expect(frame.gem?).to be_true
      end
      
      it "should be false for everything else" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/nope", 123, "foo")
        
        expect(frame.gem?).to be_false
      end
    end
    
    context "#application_path" do
      it "should chop off the application root" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        
        expect(frame.application_path).to eq("app/controllers/crap_controller.rb")
      end
    end
    
    context "#gem_path" do
      it "should chop of the gem path and stick (gem) there" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")
        
        expect(frame.gem_path).to eq("(gem) whatever-1.2.3/lib/whatever.rb")
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
    
    it "should not blow up if no method name is given" do
      error = StandardError.new
      
      error.stub!(:backtrace).and_return(["foo.rb:123"])
      frames = StackFrame.from_exception(error)
      frames.first.filename.should == "foo.rb"
      frames.first.line.should == 123
      
      error.stub!(:backtrace).and_return(["foo.rb:123: this is an error message"])
      frames = StackFrame.from_exception(error)
      frames.first.filename.should == "foo.rb"
      frames.first.line.should == 123
    end
    
    it "should ignore a backtrace line if its format doesn't make any sense at all" do
      error = StandardError.new
      error.stub!(:backtrace).and_return(["foo.rb:123:in `foo'", "C:in `find'", "bar.rb:123:in `bar'"])
      frames = StackFrame.from_exception(error)
      frames.count.should == 2
    end
    
    it "should not blow up if a filename contains a colon" do
      error = StandardError.new
      error.stub!(:backtrace).and_return(["crap:filename.rb:123"])
      frames = StackFrame.from_exception(error)
      frames.first.filename.should == "crap:filename.rb"
    end
  end
end
