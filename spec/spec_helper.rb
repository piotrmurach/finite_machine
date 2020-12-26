# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"
  require "coveralls"

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])

  SimpleCov.start do
    command_name "spec"
    add_filter "spec"
  end
end

require "finite_machine"
require "rspec-benchmark"

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.raise_errors_for_deprecations!
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.disable_monkey_patching!
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
  config.order = :random
end
