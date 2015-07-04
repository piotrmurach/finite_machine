# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Event, '#<<' do
  let(:machine) { double(:machine) }

  let(:object) { described_class }

  it "adds multiple transitions" do
    transition = double(:transition)
    event = object.new(machine)
    event << transition << transition
    expect(event.state_transitions).to match_array([transition, transition])
  end
end
