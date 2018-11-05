# frozen_string_literal: true

RSpec.describe FiniteMachine::Transition, '#inspect' do
  let(:machine) { double(:machine) }

  subject(:transition) { described_class.new(machine, attrs) }

  context 'when inspecting' do
    let(:attrs) { {name: :start, states: { :foo => :bar, :baz => :daz } } }

    it "displays name and transitions" do
      expect(transition.inspect).to eql("<#FiniteMachine::Transition @name=start, @transitions=foo -> bar, baz -> daz, @when=[]>")
    end
  end

  context 'when converting to string' do
    let(:attrs) { {name: :start, states: { :foo => :bar } } }

    it "displays name and transitions" do
      expect(transition.to_s).to eql("start")
    end
  end
end
