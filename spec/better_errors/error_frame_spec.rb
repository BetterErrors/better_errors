require "spec_helper"

module BetterErrors
  describe ErrorFrame do
    context "#application?" do
      it "should be true for application filenames" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = ErrorFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        
        frame.application?.should be_true
      end
      
      it "should be false for everything else" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = ErrorFrame.new("/abc/nope", 123, "foo")
        
        frame.application?.should be_false
      end
      
      it "should not care if no application_root is set" do
        frame = ErrorFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        
        frame.application?.should be_false
      end
    end
    
    context "#gem?" do
      it "should be true for gem filenames" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = ErrorFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")
        
        frame.gem?.should be_true
      end
      
      it "should be false for everything else" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = ErrorFrame.new("/abc/nope", 123, "foo")
        
        frame.gem?.should be_false
      end
    end
    
    context "#application_path" do
      it "should chop off the application root" do
        BetterErrors.stub!(:application_root).and_return("/abc/xyz")
        frame = ErrorFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        
        frame.application_path.should == "app/controllers/crap_controller.rb"
      end
    end
    
    context "#gem_path" do
      it "should chop of the gem path and stick (gem) there" do
        Gem.stub!(:path).and_return(["/abc/xyz"])
        frame = ErrorFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")
        
        frame.gem_path.should == "(gem) whatever-1.2.3/lib/whatever.rb"
      end
    end
  end
end
