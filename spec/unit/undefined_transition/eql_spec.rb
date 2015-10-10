# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::UndefinedTransition, '#==' do
  it "is true with the same name" do
    expect(described_class.new(:go)).to eq(described_class.new(:go))
  end

  it "is false with a different name" do
    expect(described_class.new(:go)).to_not eq(described_class.new(:other))
  end

  it "is false with another object" do
    expect(described_class.new(:go)).to_not eq(:other)
  end
end
