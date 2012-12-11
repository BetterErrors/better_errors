require "spec_helper"

module BetterErrors
  describe CodeFormatter do
    let(:filename) { File.expand_path("../support/my_source.rb", __FILE__) }
    
    let(:formatter) { CodeFormatter.new(filename, 8) }
    
    it "should pick an appropriate scanner" do
      expect(formatter.coderay_scanner).to eq(:ruby)
    end
    
    it "should show 5 lines of context" do
      formatter.line_range.should == (3..13)
      
      expect(formatter.context_lines).to eq([
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
        ])
    end
    
    it "should highlight the erroring line" do
      expect(formatter.html).to match(/highlight.*eight/)
    end
    
    it "should work when the line is right on the edge" do
      formatter = CodeFormatter.new(filename, 20)
      expect(formatter.line_range).to eq(15..20)
      expect(formatter.html).to_not eq(formatter.source_unavailable)
    end
    
    it "should not barf when the lines don't make any sense" do
      formatter = CodeFormatter.new(filename, 999)
      expect(formatter.html).to eq(formatter.source_unavailable)
    end
    
    it "should not barf when the file doesn't exist" do
      formatter = CodeFormatter.new("fkdguhskd7e l", 1)
      expect(formatter.html).to eq(formatter.source_unavailable)
    end
  end
end
