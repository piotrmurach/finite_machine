source "https://rubygems.org"

gemspec

gem "json", "2.4.1" if RUBY_VERSION == "2.0.0"

group :development do
  gem "ruby-prof", "~> 0.17.0", platforms: :mri
  gem "pry",   "~> 0.10.1"
  gem "rspec-benchmark", RUBY_VERSION < "2.1.0" ? "~> 0.4" : "~> 0.6"
end

group :metrics do
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.5.0")
    gem "coveralls_reborn", "~> 0.21.0"
    gem "simplecov", "~> 0.21.0"
  end
  gem "yardstick", "~> 0.9.9"
end
