# frozen_string_literal: true

RSpec.describe FiniteMachine, '#event_names' do
  it "retrieves all event names" do
    fsm = FiniteMachine.new do
      initial :green

      events {
        event :start, :red => :green
        event :stop,  :green => :red
      }
    end

    expect(fsm.current).to eql(:green)
    expect(fsm.event_names).to match_array([:init, :start, :stop])
  end
end
