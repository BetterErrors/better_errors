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
      
      it "should prioritize gem path over application path" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        Gem.stub!(:path).and_return(["/abc/xyz/vendor"])
        frame = StackFrame.new("/abc/xyz/vendor/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")
        
        frame.gem_path.should == "(gem) whatever-1.2.3/lib/whatever.rb"
      end
    end
    
    context "#pretty_path" do
      it "should return #application_path for application paths" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        frame.pretty_path.should == frame.application_path
      end
      
      it "should return #gem_path for gem paths" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")
        
        frame.pretty_path.should == frame.gem_path
      end
    end

    it "should special case SyntaxErrors" do
      syntax_error = SyntaxError.allocate
      Exception.instance_method(:initialize).bind(syntax_error).call("my_file.rb:123: you wrote bad ruby!")
      frames = StackFrame.from_exception(syntax_error)
      frames.first.filename.should == "my_file.rb"
      frames.first.line.should == 123
    end
    
    it "should not blow up if no method name is given" do
      error = StandardError.allocate
      
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
      error = StandardError.allocate
      error.stub!(:backtrace).and_return(["foo.rb:123:in `foo'", "C:in `find'", "bar.rb:123:in `bar'"])
      frames = StackFrame.from_exception(error)
      frames.count.should == 2
    end
    
    it "should not blow up if a filename contains a colon" do
      error = StandardError.allocate
      error.stub!(:backtrace).and_return(["crap:filename.rb:123"])
      frames = StackFrame.from_exception(error)
      frames.first.filename.should == "crap:filename.rb"
    end
  end
end
