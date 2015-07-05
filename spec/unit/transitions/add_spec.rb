# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Transitions, '#add' do
  it "adds a transition to find later" do
    transitions = FiniteMachine::Transitions.new

    transitions.add(:go, :red, :green)

    expect(transitions.find(:go)).to eq({:red => :green})
  end

  it "does not replace existing transition" do
    transitions = FiniteMachine::Transitions.new

    transitions.add(:go, :red, :green)
    transitions.add(:go, :red, :yellow)

    expect(transitions.find(:go)).to include({:red => [:green, :yellow]})
  end

  it "does not replace existing event" do
    transitions = FiniteMachine::Transitions.new

    transitions.add(:go, :red, :green)
    transitions.add(:go, :yellow, :green)

    expect(transitions.find(:go)).to include({:red => :green, :yellow => :green})
  end
end
