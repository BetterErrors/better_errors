require "spec_helper"

RSpec.describe BetterErrors::CodeFormatter::Text do
  let(:filename) { File.expand_path("../../support/my_source.rb", __FILE__) }
  let(:line) { 8 }
  let(:formatter) { described_class.new(filename, line) }

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

  context 'when the line is right at the end of the file' do
    let(:line) { 20 }

    it "ends on the line" do
      expect(formatter.line_range).to eq(15..20)
    end
  end

  describe '#output' do
    subject(:output) { formatter.output }

    it "highlights the erroring line" do
      expect(output).to eq <<-TEXT.gsub(/^      /, "")
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

    context 'when the line is outside the file' do
      let(:line) { 999 }

      it "returns the 'source unavailable' message" do
        expect(output).to eq(formatter.source_unavailable)
      end
    end

    context 'when the the file path is not valid' do
      let(:filename) { "fkdguhskd7e l" }

      it "returns the 'source unavailable' message" do
        expect(output).to eq(formatter.source_unavailable)
      end
    end
  end
end
