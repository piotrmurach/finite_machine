RSpec.describe FiniteMachine, ":log_transitions" do
  let(:output) { StringIO.new("", "w+")}

  before { FiniteMachine.logger = ::Logger.new(output) }

  after  { FiniteMachine.logger = ::Logger.new($stderr) }

  it "logs transitions" do
    fsm = FiniteMachine.new name: "TrafficLights", log_transitions: true do
      initial :green

      event :slow, :green  => :yellow
      event :stop, :yellow => :red
    end

    fsm.slow
    output.rewind
    expect(output.read).to match(/Transition: @machine=TrafficLights @event=slow green -> yellow/)

    fsm.stop(1, 2)
    output.rewind
    expect(output.read).to match(/Transition: @machine=TrafficLights @event=stop @with=\[1,2\] yellow -> red/)
  end
end
