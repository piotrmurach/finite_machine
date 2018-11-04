# frozen_string_literal: true

RSpec.describe FiniteMachine::EventsMap do
  it "finds current states for event name" do
    transition = spy(:transition, states: {:red => :yellow, :yellow => :green})
    events_map = described_class.new
    events_map.add(:start, transition)

    expect(events_map.states_for(:start)).to eq([:red, :yellow])
  end

  it "fails to find any states for event name" do
    events_map = described_class.new

    expect(events_map.states_for(:start)).to eq([])
  end
end
