# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Transitions, '#find' do
  it "returns unknown transition" do
    transitions = FiniteMachine::Transitions.new

    expect(transitions.find(:unknown)).to eq({})
  end
end
