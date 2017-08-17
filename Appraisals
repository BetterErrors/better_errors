appraise "rails42" do
  gem 'rails', '~> 4.2.0'
  gem 'nokogiri', RUBY_VERSION < '2.1' ? '~> 1.6.0' : '>= 1.7'
end

appraise "rails50" do
  gem 'rails', '~> 5.0.0'
end

appraise "rails51" do
  gem 'rails', '~> 5.1.0'
end

appraise "rails42_haml" do
  gem 'rails', '~> 4.2.0'
  gem 'nokogiri', RUBY_VERSION < '2.1' ? '~> 1.6.0' : '>= 1.7'
  gem 'haml'
end

appraise "rails50_haml" do
  gem 'rails', '~> 5.0.0'
  gem 'haml'
end

appraise "rails51_haml" do
  gem 'rails', '~> 5.1.0'
  gem 'haml'
end

appraise "rails42_boc" do
  gem 'rails', '~> 4.2.0'
  gem 'nokogiri', RUBY_VERSION < '2.1' ? '~> 1.6.0' : '>= 1.7'
  gem "binding_of_caller", platforms: :ruby
end

appraise "rails50_boc" do
  gem 'rails', '~> 5.0.0'
  gem "binding_of_caller", platforms: :ruby
end

appraise "rails51_boc" do
  gem 'rails', '~> 5.1.0'
  gem "binding_of_caller", platforms: :ruby
end

appraise 'rack' do
end

appraise 'rack_boc' do
  gem 'binding_of_caller'
end

# To be removed in the future once the Pry REPL is extracted from this project.
appraise "pry09" do
  gem "pry", "~> 0.9.12"
end

# To be removed in the future once the Pry REPL is extracted from this project.
appraise "pry010" do
  gem "pry", "~> 0.10.0"
end

# To be removed in the future once the Pry REPL is extracted from this project.
appraise "pry011" do
  gem "pry", "~> 0.11.0pre"
end
