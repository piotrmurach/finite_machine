# frozen_string_literal: true

RSpec.describe FiniteMachine, 'handlers' do
  before(:each) {
    stub_const("DummyLogger", Class.new do
      attr_reader :result

      def log_error(exception)
        @result = "log_error(#{exception})"
      end

      def raise_error
        raise FiniteMachine::TransitionError
      end
    end)
  }

  it "allows to customise error handling" do
    called = []
    fsm = FiniteMachine.new do
      initial :green

      event :slow, :green  => :yellow
      event :stop, :yellow => :red

      handlers {
        handle FiniteMachine::InvalidStateError do |exception|
          called << 'invalidstate'
        end
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.stop
    expect(fsm.current).to eql(:green)
    expect(called).to eql([
      'invalidstate'
    ])
  end

  it 'allows for :with to be symbol' do
    logger = DummyLogger.new
    fsm = FiniteMachine.new(logger) do
      initial :green

      event :slow, :green  => :yellow
      event :stop, :yellow => :red

      handlers {
        handle FiniteMachine::InvalidStateError, with: :log_error
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.stop
    expect(fsm.current).to eql(:green)
    expect(logger.result).to eql('log_error(FiniteMachine::InvalidStateError)')
  end

  it 'allows for error type as string' do
    logger = DummyLogger.new
    called = []
    fsm = FiniteMachine.new(target: logger) do
      initial :green

      event :slow, :green  => :yellow
      event :stop, :yellow => :red

      on_enter_yellow do |event|
        raise_error
      end

      handlers {
        handle 'InvalidStateError' do |exception|
          called << 'invalid_state_error'
        end
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.stop
    expect(fsm.current).to eql(:green)
    expect(called).to eql(['invalid_state_error'])
  end

  it 'allows for empty block handler' do
    called = []
    fsm = FiniteMachine.new do
      initial :green

      event :slow, :green  => :yellow
      event :stop, :yellow => :red

      handlers {
        handle FiniteMachine::InvalidStateError do
          called << 'invalidstate'
        end
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.stop
    expect(fsm.current).to eql(:green)
    expect(called).to eql([
      'invalidstate'
    ])
  end

  it 'requires error handler' do
    expect { FiniteMachine.new do
      initial :green

      event :slow, :green => :yellow

      handlers {
        handle 'UnknownErrorType'
      }
    end }.to raise_error(ArgumentError, /error handler/)
  end

  it 'checks handler class to be Exception' do
    expect { FiniteMachine.new do
      initial :green

      event :slow, :green => :yellow

      handlers {
        handle Object do end
      }
    end }.to raise_error(ArgumentError, /Object isn't an Exception/)
  end
end
