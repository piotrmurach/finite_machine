require 'finite_machine'

3.times do
  puts

  GC.start

  gc_before = GC.stat
  objects_before = ObjectSpace.count_objects[:T_OBJECT]
  p objects_before

  1_000.times do
    FiniteMachine.define
  end

  objects_after = ObjectSpace.count_objects
  gc_after = GC.stat
  p objects_after

  p "GC count: #{gc_after[:count] - gc_before[:count]}"
  p "Objects count: #{}"
end
