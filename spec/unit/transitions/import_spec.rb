# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Transitions, '#import' do
  it "imports transitions for a given event name" do
    transitions = FiniteMachine::Transitions.new
    states = {:red => :yellow, :green => :red}

    transitions.import(:go, states)

    expect(transitions.find(:go)).to include(states)
  end
end
