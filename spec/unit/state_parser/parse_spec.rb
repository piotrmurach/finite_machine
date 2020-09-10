# frozen_string_literal: true

RSpec.describe FiniteMachine::StateParser, "#parse" do
  let(:object) { described_class }

  context "when no attributes" do
    let(:attrs) { { } }

    it "raises error for no transitions" do
      expect {
        object.parse(attrs)
      }.to raise_error(FiniteMachine::NotEnoughTransitionsError,
                       /please provide state transitions/)
    end
  end

  context "when :from and :to keys" do
    let(:attrs) { { from: :green, to: :yellow }}

    it "removes :from and :to keys" do
      expect(object.parse(attrs)).to eq({green: :yellow})
    end
  end

  context "when only :from key" do
    let(:attrs) { { from: :green }}

    it "adds to state as copy of from" do
      expect(object.parse(attrs)).to eq({green: :green})
    end
  end

  context "when only :to key" do
    let(:attrs) { { to: :green }}

    it "inserts :any from state" do
      expect(object.parse(attrs)).to eq({FiniteMachine::ANY_STATE => :green})
    end
  end

  context "when attribuets as hash" do
    let(:attrs) { { green: :yellow } }

    it "copies attributes over" do
      expect(object.parse(attrs)).to eq({green: :yellow})
    end
  end

  context "when array of from states" do
    let(:attrs) { { [:green, :red] => :yellow } }

    it "extracts states" do
      expect(object.parse(attrs)).to include({red: :yellow, green: :yellow})
    end
  end
end
