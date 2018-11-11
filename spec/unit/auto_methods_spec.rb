# frozen_string_literal: true

RSpec.describe FiniteMachine, ':auto_methods' do
  it "allows turning off automatic methods generation" do
    fsm = FiniteMachine.new(auto_methods: false) do
      initial :green

      event :slow,  :green  => :yellow
      event :stop,  :yellow => :red
      event :ready, :red    => :yellow
      event :go,    :yellow => :green

      callbacks {
        # allows for fluid callback names
        once_on_enter_yellow do |event| 'once_on_enter_yellow' end
      }
    end

    expect(fsm.respond_to?(:slow)).to eq(false)
    expect { fsm.slow }.to raise_error(NoMethodError)
    expect(fsm.current).to eq(:green)

    fsm.trigger(:slow)
    expect(fsm.current).to eq(:yellow)
  end

  it "allows to use any method name without auto method generation" do
    fsm = FiniteMachine.new(auto_methods: false) do
      initial :green

      event :fail, :green => :red
    end

    fsm.trigger(:fail)
    expect(fsm.current).to eq(:red)
  end

  it "detects dangerous event names" do
    expect {
      FiniteMachine.new do
        event :trigger, :a => :b
      end
    }.to raise_error(FiniteMachine::AlreadyDefinedError)
  end
end

