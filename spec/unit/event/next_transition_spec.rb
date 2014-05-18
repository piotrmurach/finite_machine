# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Event, '#next_transition' do
  let(:object) { described_class }

  subject(:event) { object.new(machine, name: :test) }

  describe "matches transition by name" do
    let(:machine) { double(:machine, current: :b) }

    it "finds matching transition" do
      transition_a = double(:transition_a, from_state: :a)
      transition_b = double(:transition_b, from_state: :b)
      event << transition_a
      event << transition_b

      expect(event.next_transition).to eq(transition_b)
    end
  end

  describe "matches :any transition" do
    let(:machine) { double(:machine, current: :any) }

    it "finds matching transition" do
      transition_a   = double(:transition_a, from_state: :a)
      transition_any = double(:transition_any, from_state: :any)
      event << transition_a
      event << transition_any

      expect(event.next_transition).to eq(transition_any)
    end
  end

  describe "fails to find" do
    let(:machine) { double(:machine, current: :c) }

    it "choses first available transition" do
      transition_a = double(:transition_a, from_state: :a)
      transition_b = double(:transition_b, from_state: :b)
      event << transition_a
      event << transition_b

      expect(event.next_transition).to eq(transition_a)
    end
  end
end
