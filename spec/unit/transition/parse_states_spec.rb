# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::Transition, 'parse_states' do

  let(:object) { described_class.new(attrs) }

  subject(:transition) { object.parse_states(attrs) }

  context 'with :from, :to keys' do
    let(:attrs) { {from: [:green, :yellow], to: :red} }

    it "groups states" do
      expect(transition).to eql([[:green, :yellow], :red])
    end
  end

  context 'when from array' do
    let(:attrs) { {[:green, :yellow] => :red} }

    it "groups states" do
      expect(transition).to eql([[:green, :yellow], :red])
    end
  end

  context 'when hash of states' do
    let(:attrs) { { :green => :red, :yellow => :red} }

    it "groups states" do
      expect(transition).to eql([[:green, :yellow], :red])
    end
  end
end
