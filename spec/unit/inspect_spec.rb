# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Transition, 'inspect' do
  let(:machine) { double }

  subject(:transition) { described_class.new(machine, attrs) }

  context 'when inspecting' do
    let(:attrs) { {name: :start, :foo => :bar, :baz => :daz} }

    it "displays name and transitions" do
      expect(transition.inspect).to eql("<#FiniteMachine::Transition @name=start, @transitions=foo -> bar, baz -> daz, @when=[]>")
    end
  end

  context 'when converting to string' do
    let(:attrs) { {name: :start, :foo => :bar } }

    it "displays name and transitions" do
      expect(transition.to_s).to eql("start")
    end
  end
end
