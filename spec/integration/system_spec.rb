# frozen_string_literal: true

RSpec.describe FiniteMachine, 'system' do

  it "doesn't share state between machine callbacks" do
    callbacks = []
    stub_const("FSM_A", Class.new(FiniteMachine::Definition) do
      event :init, :none => :green
      event :start, any_state => :green

      callbacks {
        on_before do |event|
          callbacks << "fsmA on_before(#{event.name})"
        end
        on_enter_green do |event|
          target.fire
          callbacks << "fsmA on_enter(:green)"
        end
        once_on_enter_green do |event|
          callbacks << "fsmA once_on_enter(:green)"
        end
      }
    end)

    stub_const("FSM_B", Class.new(FiniteMachine::Definition) do
      event :init,  :none    => :stopped
      event :start, :stopped => :started

      callbacks {
        on_before do |event|
          callbacks << "fsmB on_before(#{event.name})"
        end
        on_enter_stopped do |event|
          callbacks << "fsmB on_enter(:stopped)"
        end
        on_enter_started do |event|
          callbacks << "fsmB on_enter(:started)"
        end
      }
    end)

    class Backend
      def initialize
        @fsmB = FSM_B.new
        @fsmB.init
        @signal = Mutex.new
      end

      def operate
        @signal.unlock if @signal.locked?
        @worker = Thread.new do
          while !@signal.locked? do
            sleep 0.01
          end
          Thread.current.abort_on_exception = true
          @fsmB.start
        end
      end

      def stopit
        @signal.lock
        @worker.join
      end
    end

    class Fire
      def initialize
        @fsmA = FSM_A.new(self)

        @backend = Backend.new
        @backend.operate
      end

      def fire
        @backend.stopit
      end

      def operate
        #@fsmA.start # should trigger as well
        @fsmA.init
      end
    end

    fire = Fire.new
    fire.operate

    expect(callbacks).to match_array([
      'fsmB on_before(init)',
      'fsmB on_enter(:stopped)',
      'fsmA on_before(init)',
      'fsmA on_enter(:green)',
      'fsmA once_on_enter(:green)',
      'fsmB on_before(start)',
      'fsmB on_enter(:started)'
    ])
  end
end
