# frozen_string_literal: true

RSpec.describe FiniteMachine::EventsMap, "#events" do
  it "has no event names" do
    events_map = described_class.new
    expect(events_map.events).to eq([])
  end

  it "returns all event names" do
    events_map = described_class.new
    transition = double(:transition)
    events_map.add(:ready, transition)
    events_map.add(:go, transition)
    expect(events_map.events).to match_array([:ready, :go])
  end
end
