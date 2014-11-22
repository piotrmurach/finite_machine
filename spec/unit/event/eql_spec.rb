# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Event, 'eql?' do
  let(:machine) { double(:machine) }
  let(:name)    { :green }
  let(:options) { {} }
  let(:object)  { described_class }

  subject(:event) { object.new(machine, options) }

  context 'with the same object' do
   let(:other) { event }

    it "equals" do
      expect(event).to eql(other)
    end
  end

  context 'with an equivalent object' do
    let(:other) { event.dup }

    it "equals" do
      expect(event).to eql(other)
    end
  end

  context "with an object having different name" do
    let(:other_name) { :red }
    let(:other) { object.new(machine, {name: other_name}) }

    it "doesn't equal" do
      expect(event).to_not eql(other)
    end
  end
end
