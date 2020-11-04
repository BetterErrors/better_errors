require 'spec_helper'

RSpec.describe BetterErrors::ExceptionHint do
  let(:described_instance) { described_class.new(exception) }

  describe '#hint' do
    subject(:hint) { described_instance.hint }

    context "when the exception is a NameError" do
      let(:exception) {
        begin
          foo
        rescue NameError => e
          e
        end
      }

      it { is_expected.to eq("`foo` is probably misspelled.") }
    end

    context "when the exception is a NoMethodError" do
      let(:exception) {
        begin
          val.foo
        rescue NoMethodError => e
          e
        end
      }

      context "on `nil`" do
        let(:val) { nil }

        it { is_expected.to eq("Something is `nil` when it probably shouldn't be.") }
      end

      context 'on an unnamed object type' do
        let(:val) { Class.new }

        it { is_expected.to be_nil }
      end

      context "on other values" do
        let(:val) { 42 }

        it {
          is_expected.to match(
            /`foo` is being called on a `(Integer|Fixnum)` object, which might not be the type of object you were expecting./
          )
        }
      end
    end
  end
end
