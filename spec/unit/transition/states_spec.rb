# frozen_string_literal: true

RSpec.describe FiniteMachine::Transition, "#states" do
  let(:machine) { double(:machine) }

  it "groups states with :to key only" do
    attrs = {states: {:any => :red}}
    transition = FiniteMachine::Transition.new(machine, :event_name, attrs)
    expect(transition.states).to eql({any: :red})
  end

  it "groups states when from array" do
    attrs = {states: { :green => :red, :yellow => :red}}
    transition = FiniteMachine::Transition.new(machine, :event_name, attrs)
    expect(transition.states.keys).to match_array([:green, :yellow])
    expect(transition.states.values).to eql([:red, :red])
  end


  it "groups states when hash of states" do
    attrs = {states: {
              :initial => :low,
              :low     => :medium,
              :medium  => :high }}
    transition = FiniteMachine::Transition.new(machine, :event_name, attrs)
    expect(transition.states.keys).to match_array([:initial, :low, :medium])
    expect(transition.states.values).to eql([:low, :medium, :high])
  end
end
