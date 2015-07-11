# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Event, 'new' do
  let(:machine) { double(:machine) }
  let(:name)    { :green }
  let(:options) { {} }
  let(:object)  { described_class }

  subject(:event) { object.new(machine, options) }

  context "by default" do
    it "sets name to :none" do
      expect(event.name).to eql(:none)
    end
  end

  context "with custom data" do
    let(:options) { {name: name} }

    it "sets name to :green" do
      expect(event.name).to eql(name)
    end
  end

  it "freezes object" do
    expect { event.name = :red }.to raise_error(RuntimeError)
  end
end
