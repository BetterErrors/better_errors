require "spec_helper"

RSpec.describe BetterErrors::CodeFormatter::HTML do
  let(:filename) { File.expand_path("../../support/my_source.rb", __FILE__) }
  let(:line) { 8 }
  let(:formatter) { described_class.new(filename, line) }

  it "shows 5 lines of context above and below the line" do
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

  it "highlights the erroring line" do
    formatter = described_class.new(filename, 8)
    expect(formatter.output).to match(/highlight.*eight/)
  end

  it "works when the line is right on the edge" do
    formatter = described_class.new(filename, 20)
    expect(formatter.output).not_to eq(formatter.source_unavailable)
  end

  it "doesn't barf when the lines don't make any sense" do
    formatter = described_class.new(filename, 999)
    expect(formatter.output).to eq(formatter.source_unavailable)
  end

  it "doesn't barf when the file doesn't exist" do
    formatter = described_class.new("fkdguhskd7e l", 1)
    expect(formatter.output).to eq(formatter.source_unavailable)
  end
end
