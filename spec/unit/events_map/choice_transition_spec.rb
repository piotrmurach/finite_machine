# frozen_string_literal: true

RSpec.describe FiniteMachine::EventsMap, "#choice_transition?" do
  it "checks if transition has many branches" do
    transition_a = double(:transition_a, matches?: true)
    transition_b = double(:transition_b, matches?: true)

    events_map = described_class.new
    events_map.add(:go, transition_a)
    events_map.add(:go, transition_b)

    expect(events_map.choice_transition?(:go, :green)).to eq(true)
  end

  it "checks that transition has no branches" do
    transition_a = double(:transition_a, matches?: false)
    transition_b = double(:transition_b, matches?: true)

    events_map = described_class.new
    events_map.add(:go, transition_a)
    events_map.add(:go, transition_b)

    expect(events_map.choice_transition?(:go, :green)).to eq(false)
  end
end
