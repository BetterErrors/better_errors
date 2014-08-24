require "spec_helper"

module BetterErrors
  describe StackFrame do
    context "#application?" do
      it "is true for application filenames" do
        BetterErrors.stub(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")

        frame.should be_application
      end

      it "is false for everything else" do
        BetterErrors.stub(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/nope", 123, "foo")

        frame.should_not be_application
      end

      it "doesn't care if no application_root is set" do
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")

        frame.should_not be_application
      end
    end

    context "#gem?" do
      it "is true for gem filenames" do
        Gem.stub(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")

        frame.should be_gem
      end

      it "is false for everything else" do
        Gem.stub(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/nope", 123, "foo")

        frame.should_not be_gem
      end
    end

    context "#application_path" do
      it "chops off the application root" do
        BetterErrors.stub(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")

        frame.application_path.should == "app/controllers/crap_controller.rb"
      end
    end

    context "#gem_path" do
      it "chops of the gem path and stick (gem) there" do
        Gem.stub(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")

        frame.gem_path.should == "whatever (1.2.3) lib/whatever.rb"
      end

      it "prioritizes gem path over application path" do
        BetterErrors.stub(:application_root).and_return("/abc/xyz")
        Gem.stub(:path).and_return(["/abc/xyz/vendor"])
        frame = StackFrame.new("/abc/xyz/vendor/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")

        frame.gem_path.should == "whatever (1.2.3) lib/whatever.rb"
      end
    end

    context "#pretty_path" do
      it "returns #application_path for application paths" do
        BetterErrors.stub(:application_root).and_return("/abc/xyz")
        frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index")
        frame.pretty_path.should == frame.application_path
      end

      it "returns #gem_path for gem paths" do
        Gem.stub(:path).and_return(["/abc/xyz"])
        frame = StackFrame.new("/abc/xyz/gems/whatever-1.2.3/lib/whatever.rb", 123, "foo")

        frame.pretty_path.should == frame.gem_path
      end
    end

    it "special cases SyntaxErrors" do
      begin
        eval(%{ raise SyntaxError, "you wrote bad ruby!" }, nil, "my_file.rb", 123)
      rescue SyntaxError => syntax_error
      end
      frames = StackFrame.from_exception(syntax_error)
      frames.first.filename.should == "my_file.rb"
      frames.first.line.should == 123
    end

    it "doesn't blow up if no method name is given" do
      error = StandardError.allocate

      error.stub(:backtrace).and_return(["foo.rb:123"])
      frames = StackFrame.from_exception(error)
      frames.first.filename.should == "foo.rb"
      frames.first.line.should == 123

      error.stub(:backtrace).and_return(["foo.rb:123: this is an error message"])
      frames = StackFrame.from_exception(error)
      frames.first.filename.should == "foo.rb"
      frames.first.line.should == 123
    end

    it "ignores a backtrace line if its format doesn't make any sense at all" do
      error = StandardError.allocate
      error.stub(:backtrace).and_return(["foo.rb:123:in `foo'", "C:in `find'", "bar.rb:123:in `bar'"])
      frames = StackFrame.from_exception(error)
      frames.count.should == 2
    end

    it "doesn't blow up if a filename contains a colon" do
      error = StandardError.allocate
      error.stub(:backtrace).and_return(["crap:filename.rb:123"])
      frames = StackFrame.from_exception(error)
      frames.first.filename.should == "crap:filename.rb"
    end

    it "doesn't blow up with a BasicObject as frame binding" do
      obj = BasicObject.new
      def obj.my_binding
        ::Kernel.binding
      end
      frame = StackFrame.new("/abc/xyz/app/controllers/crap_controller.rb", 123, "index", obj.my_binding)
      frame.class_name.should == 'BasicObject'
    end

    it "sets method names properly" do
      obj = "string"
      def obj.my_method
        begin
          raise "foo"
        rescue => err
          err
        end
      end

      frame = StackFrame.from_exception(obj.my_method).first
      if BetterErrors.binding_of_caller_available?
        frame.method_name.should == "#my_method"
        frame.class_name.should == "String"
      else
        frame.method_name.should == "my_method"
        frame.class_name.should == nil
      end
    end

    if RUBY_ENGINE == "java"
      it "doesn't blow up on a native Java exception" do
        expect { StackFrame.from_exception(java.lang.Exception.new) }.to_not raise_error
      end
    end
  end
end
