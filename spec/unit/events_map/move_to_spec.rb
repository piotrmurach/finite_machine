# frozen_string_literal: true

RSpec.describe FiniteMachine::EventsMap, '#move_to' do
  it "moves to state by matching individual transition" do
    transition_a = double(:transition_a, matches?: false)
    transition_b = double(:transition_b, matches?: true)

    events_map = described_class.new
    events_map.add(:go, transition_a)
    events_map.add(:go, transition_b)

    allow(transition_b).to receive(:to_state).with(:yellow).and_return(:red)

    expect(events_map.move_to(:go, :yellow)).to eq(:red)
    expect(transition_b).to have_received(:to_state).with(:yellow)
  end

  it "moves to state by matching choice transition" do
    transition_a = double(:transition_a, matches?: true)
    transition_b = double(:transition_b, matches?: true)

    events_map = described_class.new
    events_map.add(:go, transition_a)
    events_map.add(:go, transition_b)

    allow(transition_a).to receive(:check_conditions).and_return(false)
    allow(transition_b).to receive(:check_conditions).and_return(true)

    allow(transition_b).to receive(:to_state).with(:green).and_return(:red)

    expect(events_map.move_to(:go, :green)).to eq(:red)
    expect(transition_b).to have_received(:to_state).with(:green)
  end

  it "moves to from state if no transition available" do
    transition_a = double(:transition_a, matches?: false)
    transition_b = double(:transition_b, matches?: false)

    events_map = described_class.new
    events_map.add(:go, transition_a)
    events_map.add(:go, transition_b)

    expect(events_map.move_to(:go, :green)).to eq(:green)
  end
end
