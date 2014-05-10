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

  context 'with :to key only' do
    let(:attrs) { { to: :red } }

    it "groups states" do
      expect(transition.from_states).to eq([:any])
      expect(transition.to_states).to eq([:red])
      expect(transition.map).to eql({any: :red})
    end
  end

  context 'with :from, :to keys' do
    let(:attrs) { {from: [:green, :yellow], to: :red} }

    it "groups states" do
      expect(transition.from_states).to match_array(attrs[:from])
      expect(transition.to_states).to match_array([:red, :red])
    end
  end

  context 'when from array' do
    let(:attrs) { {[:green, :yellow] => :red} }

    it "groups states" do
      expect(transition.from_states).to match_array([:green, :yellow])
      expect(transition.to_states).to eql([:red, :red])
    end
  end

  context 'when hash of states' do
    let(:attrs) {
      { :initial => :low,
        :low     => :medium,
        :medium  => :high }
     }

    it "groups states" do
      expect(transition.from_states).to match_array([:initial, :low, :medium])
      expect(transition.to_states).to eql([:low, :medium, :high])
    end
  end
end
