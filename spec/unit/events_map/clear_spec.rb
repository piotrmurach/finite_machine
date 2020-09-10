# frozen_string_literal: true

RSpec.describe FiniteMachine::EventsMap, "#clear" do
  it "clears map events" do
    event = double(:event)
    events_map = described_class.new
    events_map.add(:validated, event)
    expect(events_map.empty?).to be(false)

    events_map.clear
    expect(events_map.empty?).to be(true)
  end
end
