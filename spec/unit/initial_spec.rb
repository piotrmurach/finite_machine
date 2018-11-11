# frozen_string_literal: true

RSpec.describe FiniteMachine, 'initial' do

  before(:each) {
    stub_const("DummyLogger", Class.new do
      attr_accessor :level

      def initialize
        @level = :pending
      end
    end)
  }

  it "defaults initial state to :none" do
    fsm = FiniteMachine.new do
      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    end

    expect(fsm.current).to eql(:none)
  end

  it "requires initial state transition from :none" do
    fsm = FiniteMachine.new do
      event :init, :none   => :green
      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    end

    expect(fsm.current).to eql(:none)
    fsm.init
    expect(fsm.current).to eql(:green)
  end

  it "allows to specify inital state" do
    called = []
    fsm = FiniteMachine.new do
      initial :green

      event :slow, :green  => :yellow
      event :stop, :yellow => :red

      on_exit :none   do |event| called << 'on_exit_none' end
      on_enter :green do |event| called << 'on_enter_green' end
    end
    expect(fsm.current).to eql(:green)
    expect(called).to be_empty
  end

  it "allows to specify initial state through parameter" do
    fsm = FiniteMachine.new initial: :green do
      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    end
    expect(fsm.current).to eql(:green)
  end

  it "allows to specify deferred inital state" do
    fsm = FiniteMachine.new do
      initial :green, defer: true

      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    end

    expect(fsm.current).to eql(:none)
    fsm.init
    expect(fsm.current).to eql(:green)
  end

  it "raises error when specyfying initial without state name" do
    expect {
      FiniteMachine.new do
        initial defer: true

        event :slow, :green  => :yellow
        event :stop, :yellow => :red
      end
    }.to raise_error(FiniteMachine::MissingInitialStateError)
  end

  it "allows to specify inital start event" do
    fsm = FiniteMachine.new do
      initial :green, event: :start

      event :slow, :green  => :none
      event :stop, :yellow => :red
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:none)
    fsm.start
    expect(fsm.current).to eql(:green)
  end

  it "allows to specify deferred inital start event" do
    fsm = FiniteMachine.new do
      initial :green, event: :start, defer: true

      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    end

    expect(fsm.current).to eql(:none)
    fsm.start
    expect(fsm.current).to eql(:green)
  end

  it "evaluates initial state" do
    logger = DummyLogger.new
    fsm = FiniteMachine.new do
      initial logger.level

      event :slow, :green  => :none
      event :stop, :yellow => :red
    end
    expect(fsm.current).to eql(:pending)
  end

  it "doesn't care about state type" do
    fsm = FiniteMachine.new do
      initial 1

      event :a, 1 => 2
      event :b, 2 => 3
    end
    expect(fsm.current).to eql(1)
    fsm.a
    expect(fsm.current).to eql(2)
    fsm.b
    expect(fsm.current).to eql(3)
  end

  it "allows to retrieve initial state" do
    fsm = FiniteMachine.new do
      initial :green

      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    end
    expect(fsm.current).to eq(:green)
    expect(fsm.initial_state).to eq(:green)
    fsm.slow
    expect(fsm.current).to eq(:yellow)
    expect(fsm.initial_state).to eq(:green)
  end

  it "allows to retrieve initial state for deferred" do
    fsm = FiniteMachine.new do
      initial :green, defer: true

      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    end
    expect(fsm.current).to eq(:none)
    expect(fsm.initial_state).to eq(:none)
    fsm.init
    expect(fsm.current).to eq(:green)
    expect(fsm.initial_state).to eq(:green)
  end

  it "allows to trigger callbacks on initial with :silent option" do
    called = []
    fsm = FiniteMachine.new do
      initial :green, silent: false

      event :slow, :green => :yellow

      on_enter :green do |event| called << 'on_enter_green' end
    end
    expect(fsm.current).to eq(:green)
    expect(called).to eq(['on_enter_green'])
  end

  it "allows to trigger callbacks on deferred initial state" do
    called = []
    fsm = FiniteMachine.new do
      initial :green, silent: false, defer: true

      event :slow, :green => :yellow

      on_enter :green do |event| called << 'on_enter_green' end
    end
    expect(fsm.current).to eq(:none)
    fsm.init
    expect(called).to eq(['on_enter_green'])
  end
end
