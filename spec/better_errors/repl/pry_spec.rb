require "spec_helper"
require "better_errors/repl/shared_examples"

if defined? ::Pry
  RSpec.describe 'BetterErrors::REPL::Pry' do
    before(:all) do
      load "better_errors/repl/pry.rb"
    end
    after(:all) do
      # Ensure the Pry REPL file has not been included. If this is not done,
      # the constant leaks into other examples.
      # In practice, this constant is only defined if `use_pry!` is called and then the
      # REPL is used, causing BetterErrors::REPL to require the file.
      BetterErrors::REPL.send(:remove_const, :Pry)
    end

    let(:fresh_binding) {
      local_a = 123
      binding
    }

    let!(:exception) { raise ZeroDivisionError, "you divided by zero you silly goose!" rescue $! }

    let(:repl) { BetterErrors::REPL::Pry.new(fresh_binding, exception) }

    it "does line continuation", :aggregate_failures do
      output, prompt, filled = repl.send_input ""
      expect(output).to eq("=> nil\n")
      expect(prompt).to eq(">>")
      expect(filled).to eq("")

      output, prompt, filled = repl.send_input "def f(x)"
      expect(output).to eq("")
      expect(prompt).to eq("..")
      expect(filled).to eq("  ")

      output, prompt, filled = repl.send_input "end"
      if RUBY_VERSION >= "2.1.0"
        expect(output).to eq("=> :f\n")
      else
        expect(output).to eq("=> nil\n")
      end
      expect(prompt).to eq(">>")
      expect(filled).to eq("")
    end

    it_behaves_like "a REPL provider"
  end
else
  puts "Skipping Pry specs because pry is not in the bundle"
end
