# frozen_string_literal: true

RSpec.describe FiniteMachine::HookEvent, 'eql?' do
  let(:name)       { :green }
  let(:event_name) { :go }
  let(:object)     { described_class }

  subject(:hook) { object.new(name, event_name, name) }

  context 'with the same object' do
   let(:other) { hook }

    it "equals" do
      expect(hook).to eql(other)
    end
  end

  context 'with an equivalent object' do
    let(:other) { hook.dup }

    it "equals" do
      expect(hook).to eql(other)
    end
  end

  context "with an object having different name" do
    let(:other_name) { :red }
    let(:other) { object.new(other_name, event_name, other_name) }

    it "doesn't equal" do
      expect(hook).not_to eql(other)
    end
  end
end
