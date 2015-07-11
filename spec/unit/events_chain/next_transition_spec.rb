# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Event, '#next_transition' do
  let(:object) { described_class }

  subject(:event) { object.new(machine, name: :test) }

  describe "matches transition by name" do
    let(:machine) { double(:machine) }

    it "finds matching transition" do
      transition_a = double(:transition_a, current?: false)
      transition_b = double(:transition_b, current?: true)
      event << transition_a
      event << transition_b

      expect(event.next_transition).to eq(transition_b)
    end
  end

  describe "fails to find" do
    let(:machine) { double(:machine) }

    it "choses first available transition" do
      transition_a = double(:transition_a, current?: false)
      transition_b = double(:transition_b, current?: false)
      event << transition_a
      event << transition_b

      expect(event.next_transition).to eq(transition_a)
    end
  end
end
