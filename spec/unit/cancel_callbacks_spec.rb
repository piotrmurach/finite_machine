# frozen_string_literal: true

RSpec.describe FiniteMachine, 'cancell callbacks' do
  it "cancels transition on event callback" do
    fsm = FiniteMachine.new do
      initial :green

      events {
        event :slow, :green  => :yellow
        event :go,   :yellow => :green
      }

      callbacks {
        on_exit :green do |event|
          cancel_event(event)
        end
      }
    end

    expect(fsm.current).to eql(:green)
    fsm.slow
    expect(fsm.current).to eql(:green)
  end

  it "stops executing callbacks when cancelled" do
    called = []

    fsm = FiniteMachine.new do
      initial :initial

      events { event :bump, initial: :low }

      callbacks {
        on_before do |event|
          called << "enter_#{event.name}_#{event.from}_#{event.to}"

          cancel_event(event)
        end

        on_exit :initial do |event| called << "exit_initial" end
        on_exit          do |event| called << "exit_any" end
        on_enter :low    do |event| called << "enter_low" end
        on_after :bump   do |event| called << "after_#{event.name}" end
        on_after         do |event| called << "after_any" end
      }
    end

    fsm.bump

    expect(called).to eq(['enter_bump_initial_low'])
  end
end
