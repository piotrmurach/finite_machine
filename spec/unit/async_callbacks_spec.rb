# frozen_string_literal: true

RSpec.describe FiniteMachine, 'async callbacks' do
  it "permits async callback" do
    called = []
    fsm = FiniteMachine.new do
      initial :green, silent: false

      events {
        event :slow,  :green  => :yellow
        event :go,    :yellow => :green
      }

      callbacks {
        on_enter  :green,  :async  do |event| called << 'on_enter_green' end
        on_before :slow,   :async  do |event| called << 'on_before_slow'  end
        on_exit   :yellow, :async  do |event| called << 'on_exit_yellow' end
        on_after  :go,     :async  do |event| called << 'on_after_go'     end
      }
    end
    fsm.slow
    fsm.go
    sleep 0.1
    expect(called).to match_array([
      'on_enter_green',
      'on_before_slow',
      'on_exit_yellow',
      'on_enter_green',
      'on_after_go'
    ])
  end
end
