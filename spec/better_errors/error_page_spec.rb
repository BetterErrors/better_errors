require "spec_helper"

module BetterErrors
  describe ErrorPage do
    let!(:exception) { raise ZeroDivisionError, "you divided by zero you silly goose!" rescue $! }

    let(:error_page) { ErrorPage.new exception, { "PATH_INFO" => "/some/path" } }

    let(:response) { error_page.render }

    let(:empty_binding) {
      local_a = :value_for_local_a
      local_b = :value_for_local_b

      @inst_c = :value_for_inst_c
      @inst_d = :value_for_inst_d

      binding
    }

    it "includes the error message" do
      response.should include("you divided by zero you silly goose!")
    end

    it "includes the request path" do
      response.should include("/some/path")
    end

    it "includes the exception class" do
      response.should include("ZeroDivisionError")
    end

    context "variable inspection" do
      let(:exception) { empty_binding.eval("raise") rescue $! }

      if BetterErrors.binding_of_caller_available?
        it "shows local variables" do
          html = error_page.do_variables("index" => 0)[:html]
          html.should include("local_a")
          html.should include(":value_for_local_a")
          html.should include("local_b")
          html.should include(":value_for_local_b")
        end
      else
        it "tells the user to add binding_of_caller to their gemfile to get fancy features" do
          html = error_page.do_variables("index" => 0)[:html]
          html.should include(%{gem "binding_of_caller"})
        end
      end

      it "shows instance variables" do
        html = error_page.do_variables("index" => 0)[:html]
        html.should include("inst_c")
        html.should include(":value_for_inst_c")
        html.should include("inst_d")
        html.should include(":value_for_inst_d")
      end

      it "shows filter instance variables" do
        BetterErrors.stub(:ignored_instance_variables).and_return([ :@inst_d ])
        html = error_page.do_variables("index" => 0)[:html]
        html.should include("inst_c")
        html.should include(":value_for_inst_c")
        html.should_not include('<td class="name">@inst_d</td>')
        html.should_not include("<pre>:value_for_inst_d</pre>")
      end
    end

    it "doesn't die if the source file is not a real filename" do
      exception.stub(:backtrace).and_return([
        "<internal:prelude>:10:in `spawn_rack_application'"
      ])
      response.should include("Source unavailable")
    end
  end
end
