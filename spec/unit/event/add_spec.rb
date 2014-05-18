# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Event, '#<<' do
  let(:machine) { double(:machine) }

  let(:object) { described_class }

  subject(:event) { object.new(machine, name: :test) }

  it "adds multiple transitions" do
    transition = double(:transition)
    event << transition
    event << transition
    expect(event.state_transitions).to match_array([transition, transition])
  end
end
