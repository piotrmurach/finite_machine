# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Transition, 'parsed_states' do
  let(:machine) { double(:machine) }

  it "groups states with :to key only" do
    attrs = {parsed_states: {:any => :red}}
    transition = FiniteMachine::Transition.new(machine, attrs)
    expect(transition.states).to eql({any: :red})
  end

  it "groups states when from array" do
    attrs = {parsed_states: { :green => :red, :yellow => :red}}
    transition = FiniteMachine::Transition.new(machine, attrs)
    expect(transition.states.keys).to match_array([:green, :yellow])
    expect(transition.states.values).to eql([:red, :red])
  end


  it "groups states when hash of states" do
    attrs = {parsed_states: {
              :initial => :low,
              :low     => :medium,
              :medium  => :high }}
    transition = FiniteMachine::Transition.new(machine, attrs)
    expect(transition.states.keys).to match_array([:initial, :low, :medium])
    expect(transition.states.values).to eql([:low, :medium, :high])
  end
end
