# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Transition, 'parsed_states' do
  let(:machine) { double(:machine) }

  subject(:transition) { described_class.new(machine, attrs) }

  context 'with :to key only' do
    let(:attrs) { { parsed_states: { any: :red } } }

    it "groups states" do
      expect(transition.from_states).to eq([:any])
      expect(transition.to_states).to eq([:red])
      expect(transition.map).to eql({any: :red})
    end
  end

  context 'when from array' do
    let(:attrs) { {parsed_states: { :green => :red, :yellow => :red} } }

    it "groups states" do
      expect(transition.from_states).to match_array([:green, :yellow])
      expect(transition.to_states).to eql([:red, :red])
    end
  end

  context 'when hash of states' do
    let(:attrs) {
      { parsed_states:
        { :initial => :low,
          :low     => :medium,
          :medium  => :high } }
     }

    it "groups states" do
      expect(transition.from_states).to match_array([:initial, :low, :medium])
      expect(transition.to_states).to eql([:low, :medium, :high])
    end
  end
end
