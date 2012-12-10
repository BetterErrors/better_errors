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
  end
end
