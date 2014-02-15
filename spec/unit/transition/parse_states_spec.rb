# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Transition, 'parse_states' do

  let(:machine) { double }

  subject(:transition) { described_class.new(machine, attrs) }

  context 'without transitions' do
    let(:attrs) { { } }

    it "raises exception" do
      expect { transition }.to raise_error(FiniteMachine::NotEnoughTransitionsError)
    end
  end

  context 'with :from, :to keys' do
    let(:attrs) { {from: [:green, :yellow], to: :red} }

    it "groups states" do
      expect(transition.from).to eql(attrs[:from])
      expect(transition.to).to eql(attrs[:to])
    end
  end

  context 'when from array' do
    let(:attrs) { {[:green, :yellow] => :red} }

    it "groups states" do
      expect(transition.from).to eql([:green, :yellow])
      expect(transition.to).to eql(:red)
    end
  end

  context 'when hash of states' do
    let(:attrs) { { :green => :red, :yellow => :red} }

    it "groups states" do
      expect(transition.from).to eql([:green, :yellow])
      expect(transition.to).to eql(:red)
    end
  end
end
