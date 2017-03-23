require "spec_helper"

module BetterErrors
  describe CodeFormatter do
    let(:filename) { File.expand_path("../support/my_source.rb", __FILE__) }

    let(:formatter) { CodeFormatter.new(filename, 8) }

    it "picks an appropriate scanner" do
      expect(formatter.coderay_scanner).to eq(:ruby)
    end

    it "shows 5 lines of context" do
      expect(formatter.line_range).to eq(3..13)

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

    it "works when the line is right on the edge" do
      formatter = CodeFormatter.new(filename, 20)
      expect(formatter.line_range).to eq(15..20)
    end

    describe CodeFormatter::HTML do
      it "highlights the erroring line" do
        formatter = CodeFormatter::HTML.new(filename, 8)
        expect(formatter.output).to match(/highlight.*eight/)
      end

      it "works when the line is right on the edge" do
        formatter = CodeFormatter::HTML.new(filename, 20)
        expect(formatter.output).not_to eq(formatter.source_unavailable)
      end

      it "doesn't barf when the lines don't make any sense" do
        formatter = CodeFormatter::HTML.new(filename, 999)
        expect(formatter.output).to eq(formatter.source_unavailable)
      end

      it "doesn't barf when the file doesn't exist" do
        formatter = CodeFormatter::HTML.new("fkdguhskd7e l", 1)
        expect(formatter.output).to eq(formatter.source_unavailable)
      end
    end

    describe CodeFormatter::Text do
      it "highlights the erroring line" do
        formatter = CodeFormatter::Text.new(filename, 8)
        expect(formatter.output).to eq <<-TEXT.gsub(/^        /, "")
            3   three
            4   four
            5   five
            6   six
            7   seven
        >   8   eight
            9   nine
           10   ten
           11   eleven
           12   twelve
           13   thirteen
        TEXT
      end

      it "works when the line is right on the edge" do
        formatter = CodeFormatter::Text.new(filename, 20)
        expect(formatter.output).not_to eq(formatter.source_unavailable)
      end

      it "doesn't barf when the lines don't make any sense" do
        formatter = CodeFormatter::Text.new(filename, 999)
        expect(formatter.output).to eq(formatter.source_unavailable)
      end

      it "doesn't barf when the file doesn't exist" do
        formatter = CodeFormatter::Text.new("fkdguhskd7e l", 1)
        expect(formatter.output).to eq(formatter.source_unavailable)
      end
    end
  end
end
