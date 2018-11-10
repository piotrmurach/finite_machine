# frozen_string_literal: true

RSpec.describe FiniteMachine::Transition, '#inspect' do
  let(:machine) { double(:machine) }

  subject(:transition) { described_class.new(machine, event_name, attrs) }

  context 'when inspecting' do
    let(:event_name) { :start }
    let(:attrs) { { states: { :foo => :bar, :baz => :daz } } }

    it "displays name and transitions" do
      expect(transition.inspect).to eql("<#FiniteMachine::Transition @name=start, @transitions=foo -> bar, baz -> daz, @when=[]>")
    end
  end

  context 'when converting to string' do
    let(:event_name) { :start }
    let(:attrs) { { states: { :foo => :bar } } }

    it "displays name and transitions" do
      expect(transition.to_s).to eql("start")
    end
  end
end
