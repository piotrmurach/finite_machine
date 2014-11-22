# encoding: utf-8

if RUBY_VERSION > '1.9' and (ENV['COVERAGE'] || ENV['TRAVIS'])
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    command_name 'spec'
    add_filter 'spec'
  end
end

require 'finite_machine'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.raise_errors_for_deprecations!
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.disable_monkey_patching!
  config.order = :random

  # Remove defined constants
  config.before :each do
    [:Car, :DummyLogger, :Bug, :User, :Engine].each do |class_name|
      if Object.const_defined?(class_name)
        Object.send(:remove_const, class_name)
      end
    end
  end
end
