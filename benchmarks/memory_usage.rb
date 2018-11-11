# frozen_string_literal: true

require_relative '../lib/finite_machine'

5.times do
  puts

  GC.start

  gc_before = GC.stat
  objects_before = ObjectSpace.count_objects
  p objects_before[:T_OBJECT]

  1_000.times do
    FiniteMachine.new do
      initial :green

      events { event :slow, :green => :yellow }
    end
  end

  objects_after = ObjectSpace.count_objects
  gc_after = GC.stat
  p objects_after[:T_OBJECT]

  p "GC count: #{gc_after[:count] - gc_before[:count]}"
  p "Objects count: #{objects_after[:T_OBJECT] - objects_before[:T_OBJECT]}"
end
