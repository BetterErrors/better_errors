require "spec_helper"

RSpec.describe BetterErrors do
  describe ".editor" do
    context "when set to a specific value" do
      before do
        allow(BetterErrors::Editor).to receive(:editor_from_symbol).and_return(:editor_from_symbol)
        allow(BetterErrors::Editor).to receive(:for_formatting_string).and_return(:editor_from_formatting_string)
        allow(BetterErrors::Editor).to receive(:for_proc).and_return(:editor_from_proc)
      end

      context "when the value is a string" do
        it "uses BetterErrors::Editor.for_formatting_string to set the value" do
          subject.editor = "thing://%{file}"
          expect(BetterErrors::Editor).to have_received(:for_formatting_string).with("thing://%{file}")
          expect(subject.editor).to eq(:editor_from_formatting_string)
        end
      end

      context "when the value is a Proc" do
        it "uses BetterErrors::Editor.for_proc to set the value" do
          my_proc = proc { "thing" }
          subject.editor = my_proc
          expect(BetterErrors::Editor).to have_received(:for_proc).with(my_proc)
          expect(subject.editor).to eq(:editor_from_proc)
        end
      end

      context "when the value is a symbol" do
        it "uses BetterErrors::Editor.editor_from_symbol to set the value" do
          subject.editor = :subl
          expect(BetterErrors::Editor).to have_received(:editor_from_symbol).with(:subl)
          expect(subject.editor).to eq(:editor_from_symbol)
        end
      end

      context "when set to something else" do
        it "raises an ArgumentError" do
          expect { subject.editor = Class.new }.to raise_error(ArgumentError)
        end
      end
    end

    context "when no value has been set" do
      before do
        BetterErrors.instance_variable_set('@editor', nil)
        allow(BetterErrors::Editor).to receive(:default_editor).and_return(:default_editor)
      end

      it "uses BetterErrors::Editor.default_editor to set the default value" do
          expect(subject.editor).to eq(:default_editor)
          expect(BetterErrors::Editor).to have_received(:default_editor)
      end
    end
  end
end
