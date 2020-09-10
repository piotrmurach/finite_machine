# frozen_string_literal: true

RSpec.describe FiniteMachine::EventsMap, "#add" do
  it "adds transitions" do
    transition = double(:transition)
    events_map = described_class.new

    events_map.add(:validated, transition)
    expect(events_map[:validated]).to eq([transition])

    events_map.add(:validated, transition)
    expect(events_map[:validated]).to eq([transition, transition])
  end

  it "allows to map add operations" do
    events_map = described_class.new
    transition = double(:transition)

    events_map.add(:go, transition).add(:start, transition)

    expect(events_map.size).to eq(2)
  end
end
