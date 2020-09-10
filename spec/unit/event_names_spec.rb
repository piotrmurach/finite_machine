# frozen_string_literal: true

RSpec.describe FiniteMachine, "#events" do
  it "retrieves all event names" do
    fsm = FiniteMachine.new do
      initial :green

      event :start, :red => :green
      event :stop,  :green => :red
    end

    expect(fsm.current).to eql(:green)
    expect(fsm.events).to match_array([:init, :start, :stop])
  end
end
