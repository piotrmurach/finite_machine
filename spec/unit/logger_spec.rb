# encoding: utf-8

require 'spec_helper'

RSpec.describe FiniteMachine::Logger do
  let(:message) { 'error' }
  let(:log) { spy }

  subject(:logger) { described_class }

  before { allow(FiniteMachine).to receive(:logger) { log } }

  it "debugs message call" do
    expect(log).to receive(:debug).with(message)
    logger.debug(message)
  end

  it "informs message call" do
    expect(log).to receive(:info).with(message)
    logger.info(message)
  end

  it "warns message call" do
    expect(log).to receive(:warn).with(message)
    logger.warn(message)
  end

  it "errors message call" do
    expect(log).to receive(:error).with(message)
    logger.error(message)
  end

  it "reports transition" do
    logger.report_transition(:go, :red, :green)

    expect(log).to have_received(:info).with("Transition: @event=go red -> green")
  end
end
