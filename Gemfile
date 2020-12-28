source "https://rubygems.org"

gemspec

gem "json", "2.4.1" if RUBY_VERSION == "2.0.0"

group :development do
  gem "ruby-prof", "~> 0.17.0", platforms: :mri
  gem "pry",   "~> 0.10.1"
  gem "rspec-benchmark", RUBY_VERSION < "2.1.0" ? "~> 0.4" : "~> 0.6"
end

group :metrics do
  gem "coveralls", "~> 0.8.22"
  gem "simplecov", "~> 0.16.1"
  gem "yardstick", "~> 0.9.9"
end
