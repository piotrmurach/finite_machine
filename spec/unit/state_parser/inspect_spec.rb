# encoding: utf-8

require 'spec_helper'

describe FiniteMachine::StateParser, "#inspect" do
  let(:object) { described_class }

  subject(:parser) { object.new(attrs) }

  describe '#inspect' do
    let(:attrs) { { green: :yellow } }

    it "inspects parser" do
      print 'YEAH CALLLED -------------------------------1'
      expect(parser.inspect).to eq("<#FiniteMachine::StateParser @attrs=green:yellow>")
    end
  end

  describe '#to_s' do
    let(:attrs) { { green: :yellow } }

    it "prints parser attributes" do
      expect(parser.to_s).to eq(attrs.to_s)
    end
  end
end
