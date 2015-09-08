# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Transition, '.check_conditions' do
  it "verifies all conditions pass" do
    exec_conditions = 0
    ok_condition = -> { exec_conditions += 1; return true }
    fail_condition = -> { exec_conditions += 1; return false }
    machine = double(:machine, target: Object.new)

    transition = described_class.new(machine, if: [ok_condition, fail_condition])

    expect(transition.check_conditions).to eql(false)
    expect(exec_conditions).to eq(2)
  end

  it "verifies 'if' and 'unless' conditions" do
    machine = double(:machine, target: Object.new)
    exec_conditions = 0
    ok_condition = -> { exec_conditions += 1; return true }
    fail_condition = -> { exec_conditions += 1; return false }

    transition = described_class.new(machine, if: [ok_condition], unless: [fail_condition])

    expect(transition.check_conditions).to eql(true)
    expect(exec_conditions).to eq(2)
  end

  it "verifies condition with arguments" do
    machine = double(:machine, target: Object.new)
    condition = lambda { |target, arg| arg == 1 }

    transition = described_class.new(machine, if: [condition])

    expect(transition.check_conditions(2)).to eql(false)
    expect(transition.check_conditions(1)).to eql(true)
  end

  it "verifies condition on target" do
    stub_const("Car", Class.new do
      def engine_on?
        true
      end
    end)
    target = Car.new
    machine = double(:machine, target: target)
    condition = lambda { |car| car.engine_on? }

    transition = described_class.new(machine, if: condition)

    expect(transition.check_conditions).to eql(true)
  end
end
