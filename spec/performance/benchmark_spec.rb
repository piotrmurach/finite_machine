# frozen_string_literal: true

RSpec.describe FiniteMachine, perf: true do
  include RSpec::Benchmark::Matchers

  class Measurement
    attr_reader :steps, :loops

    def initialize
      @steps = 0
      @loops = 0
    end

    def inc_step
      @steps += 1
    end

    def inc_loop
      @loops += 1
    end
  end

  it "correctly loops through events" do
    measurement = Measurement.new

    fsm = FiniteMachine.new(measurement) do
      initial :green

      events {
        event :next, :green => :yellow,
                     :yellow => :red,
                     :red => :green
      }

      callbacks {
        on_enter do |event| target.inc_step; true end
        on_enter :red do |event| target.inc_loop; true end
      }
    end

    100.times { fsm.next }

    expect(measurement.steps).to eq(100)
    expect(measurement.loops).to eq(100 / 3)
  end

  it "performs at least 300 ips" do
    fsm = FiniteMachine.new do
      initial :green

      events {
        event :next, :green => :yellow,
                     :yellow => :red,
                     :red => :green
      }
    end

    expect { fsm.next }.to perform_at_least(400).ips
  end
end
