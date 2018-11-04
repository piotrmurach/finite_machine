# frozen_string_literal: true

RSpec.describe FiniteMachine::EventsMap, '#inspect' do
  it "inspects empty events map" do
    events_map = described_class.new
    expect(events_map.inspect).to eq("<#FiniteMachine::EventsMap @events_map={}>")
  end

  it "inspect events map" do
    transition = double(:transition)
    events_map = described_class.new
    events_map.add(:validated, transition)
    expect(events_map.inspect).to eq("<#FiniteMachine::EventsMap @events_map=#{{validated: [transition]}}>")
  end

  it "prints events map" do
    transition = double(:transition)
    events_map = described_class.new
    events_map.add(:validated, transition)
    expect(events_map.to_s).to eq("#{{validated: [transition]}}")
  end
end
