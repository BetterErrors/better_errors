require "spec_helper"

module BetterErrors
  describe CodeFormatter do
    let(:filename) { File.expand_path("../support/my_source.rb", __FILE__) }
    
    let(:formatter) { CodeFormatter.new(filename, 8) }
    
    it "should pick an appropriate scanner" do
      formatter.coderay_scanner.should == :ruby
    end
    
    it "should show 5 lines of context" do
      formatter.line_range.should == (3..13)
      
      formatter.context_lines.should == [
          "three\n",
          "four\n",
          "five\n",
          "six\n",
          "seven\n",
          "eight\n",
          "nine\n",
          "ten\n",
          "eleven\n",
          "twelve\n",
          "thirteen\n"
        ]
    end
    
    it "should highlight the erroring line" do
      formatter.html.should =~ /highlight.*eight/
    end
    
    it "should work when the line is right on the edge" do
      formatter = CodeFormatter.new(filename, 20)
      formatter.line_range.should == (15..20)
      formatter.html.should_not == formatter.source_unavailable
    end
    
    it "should not barf when the lines don't make any sense" do
      formatter = CodeFormatter.new(filename, 999)
      formatter.html.should == formatter.source_unavailable
    end
    
    it "should not barf when the file doesn't exist" do
      formatter = CodeFormatter.new("fkdguhskd7e l", 1)
      formatter.html.should == formatter.source_unavailable
    end
  end
end
