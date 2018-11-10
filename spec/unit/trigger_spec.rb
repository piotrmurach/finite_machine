# frozen_string_literal: true

RSpec.describe FiniteMachine::StateMachine, '#trigger' do
  it "triggers event manually" do
    called = []
    fsm = FiniteMachine.new do
      initial :red

      events {
        event :start, :red   => :green, if: proc { |_, name| called << name; true }
        event :stop,  :green => :red
      }
    end

    expect(fsm.current).to eq(:red)
    fsm.trigger(:start, 'Piotr')
    expect(fsm.current).to eq(:green)
    expect(called).to eq(['Piotr'])
  end
end
