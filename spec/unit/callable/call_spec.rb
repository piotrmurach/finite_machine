# frozen_string_literal: true

RSpec.describe FiniteMachine::Callable, "#call" do

  before(:each) {
    stub_const("Car", Class.new do
      attr_reader :result

      def initialize
        @engine_on = false
      end

      def turn_engine_on
        @result = "turn_engine_on"
        @engine_on = true
      end

      def set_engine(value = :on)
        @result = "set_engine(#{value})"
        @engine = value.to_sym == :on
      end

      def turn_engine_off
        @result = "turn_engine_off"
        @engine_on = false
      end

      def engine_on?
        @result = "engine_on"
        !!@engine_on
      end
    end)
  }

  let(:called) { [] }

  let(:target) { Car.new }

  let(:instance) { described_class.new(object) }

  context "when string" do
    let(:object) {  "engine_on?" }

    it "executes method on target" do
      instance.call(target)
      expect(target.result).to eql("engine_on")
    end
  end

  context "when string" do
    let(:object) {  "set_engine(:on)" }

    it "executes method with arguments" do
      instance.call(target)
      expect(target.result).to eql("set_engine(on)")
    end
  end

  context "when string with arguments" do
    let(:object) {  "set_engine" }

    it "executes method with arguments" do
      instance.call(target, :off)
      expect(target.result).to eql("set_engine(off)")
    end
  end

  context "when symbol" do
    let(:object) {  :set_engine }

    it "executes method on target" do
      instance.call(target)
      expect(target.result).to eql("set_engine(on)")
    end
  end

  context "when symbol with arguments" do
    let(:object) {  :set_engine }

    it "executes method on target" do
      instance.call(target, :off)
      expect(target.result).to eql("set_engine(off)")
    end
  end

  context "when proc without args" do
    let(:object) {  proc { |a| called << "block_with(#{a})" } }

    it "passes arguments" do
      instance.call(target)
      expect(called).to eql(["block_with(#{target})"])
    end
  end

  context "when proc with args" do
    let(:object) {  proc { |a,b| called << "block_with(#{a},#{b})" } }

    it "passes arguments" do
      instance.call(target, :red)
      expect(called).to eql(["block_with(#{target},red)"])
    end
  end

  context "when unknown" do
    let(:object) { Object.new }

    it "raises error" do
      expect { instance.call(target) }.to raise_error(ArgumentError)
    end
  end
end
