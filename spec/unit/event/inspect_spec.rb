# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Event, '#inspect' do
  let(:machine) { double(:machine) }

  let(:object) { described_class }

  subject(:event) { object.new(machine, name: :test) }

  it "adds multiple transitions" do
    transition = double(:transition)
    event << transition
    expect(event.inspect).to eq("<#FiniteMachine::Event @name=test, @transitions=[#{transition.inspect}]>")
  end
end
