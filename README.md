<div align="center">
  <a href="http://piotrmurach.github.io/finite_machine/"><img width="236" src="https://raw.githubusercontent.com/piotrmurach/finite_machine/master/assets/finite_machine_logo.png" alt="finite machine logo" /></a>
</div>

# FiniteMachine

[![Gem Version](https://badge.fury.io/rb/finite_machine.svg)][gem]
[![Build Status](https://secure.travis-ci.org/piotrmurach/finite_machine.svg?branch=master)][travis]
[![Build status](https://ci.appveyor.com/api/projects/status/8ho4ijacpr7b4f4t?svg=true)][appveyor]
[![Code Climate](https://codeclimate.com/github/piotrmurach/finite_machine/badges/gpa.svg)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/github/piotrmurach/finite_machine/badge.svg?branch=master)][coverage]
[![Inline docs](http://inch-ci.org/github/piotrmurach/finite_machine.svg)][inchpages]
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)][gitter]

[gem]: http://badge.fury.io/rb/finite_machine
[travis]: http://travis-ci.org/piotrmurach/finite_machine
[appveyor]: https://ci.appveyor.com/project/piotrmurach/finite-machine
[codeclimate]: https://codeclimate.com/github/piotrmurach/finite_machine
[coverage]: https://coveralls.io/github/piotrmurach/finite_machine?branch=master
[inchpages]: http://inch-ci.org/github/piotrmurach/finite_machine
[gitter]: https://gitter.im/piotrmurach/finite_machine

> A minimal finite state machine with a straightforward and intuitive syntax. You can quickly model states and transitions and register callbacks to watch for triggered transitions.

## Features

* plain object state machine
* easy [custom object integration](#29-target)
* natural DSL for declaring events, callbacks and exception handlers
* [callbacks](#4-callbacks) for state and event changes
* ability to check [reachable](#28-can-and-cannot) state(s)
* ability to check for [terminal](#25-terminal) state(s)
* transition [guard conditions](#38-conditional-transitions)
* dynamic [choice pseudostates](#39-choice-pseudostates)
* thread safe

## Installation

Add this line to your application's Gemfile:

    gem 'finite_machine'

Then execute:

    $ bundle

Or install it yourself as:

    $ gem install finite_machine

## Contents

* [1. Usage](#1-usage)
* [2. API](#2-api)
    * [2.1 new](#21-new)
    * [2.2 define](#22-define)
    * [2.3 current](#23-current)
    * [2.4 initial](#24-initial)
    * [2.5 terminal](#25-terminal)
    * [2.6 is?](#26-is)
    * [2.7 trigger](#27-trigger)
      * [2.7.1 :auto_methods](#271-auto_methods)
    * [2.8 can? and cannot?](#28-can-and-cannot)
    * [2.9 target](#29-target)
      * [2.9.1 :alias_target](#27-alias_target)
    * [2.10 restore!](#210-restore)
    * [2.11 states](#211-states)
    * [2.12 events](#212-events)
* [3. States and Transitions](#3-states-and-transitions)
    * [3.1 Triggering transitions](#31-triggering-transitions)
    * [3.2 Dangerous transitions](#32-dangerous-transitions)
    * [3.3 Multiple from states](#33-multiple-from-states)
    * [3.4 any_state transitions](#34-any_state-transitions)
    * [3.5 Collapsing transitions](#35-collapsing-transitions)
    * [3.6 Silent transitions](#36-silent-transitions)
    * [3.7 Logging transitions](#37-logging-transitions)
    * [3.8 Conditional transitions](#38-conditional-transitions)
      * [3.8.1 Using a Proc](#381-using-a-proc)
      * [3.8.2 Using a Symbol](#382-using-a-symbol)
      * [3.8.3 Using a String](#383-using-a-string)
      * [3.8.4 Combining transition conditions](#384-combining-transition-conditions)
    * [3.9 Choice pseudostates](#39-choice-pseudostates)
      * [3.9.1 Dynamic choice conditions](#391-dynamic-choice-conditions)
      * [3.9.2 Multiple from states](#392-multiple-from-states)
* [4. Callbacks](#4-callbacks)
    * [4.1 on_(enter|transition|exit)](#41-on_entertransitionexit)
    * [4.2 on_(before|after)](#42-on_beforeafter)
    * [4.3 once_on](#43-once_on)
    * [4.4 Execution sequence](#44-execution-sequence)
    * [4.5 Callback parameters](#45-callback-parameters)
    * [4.6 Duplicate callbacks](#46-duplicate-callbacks)
    * [4.7 Fluid callbacks](#47-fluid-callbacks)
    * [4.8 Methods inside callbacks](#48-methods-inside-callbacks)
    * [4.9 Cancelling callbacks](#49-cancelling-callbacks)
    * [4.10 Asynchronous callbacks](#410-asynchronous-callbacks)
    * [4.11 Instance callbacks](#411-instance-callbacks)
* [5. Error Handling](#5-error-handling)
    * [5.1 Using target](#51-using-target)
* [6. Stand-alone](#6-stand-alone)
    * [6.1 Creating a Definition](#61-creating-a-definition)
    * [6.2 Targeting definition](#62-targeting-definition)
    * [6.3 Definition inheritance](#63-definition-inheritance)
* [7. Integration](#7-integration)
    * [7.1 Plain Ruby Objects](#71-plain-ruby-objects)
    * [7.2 ActiveRecord](#72-activerecord)
    * [7.3 Transactions](#73-transactions)
* [8. Tips](#8-tips)

## 1. Usage

Here is a very simple example of a state machine:

```ruby
fm = FiniteMachine.new do
  initial :red

  event :ready, :red    => :yellow
  event :go,    :yellow => :green
  event :stop,  :green  => :red

  on_before(:ready) { |event| ... }
  on_after(:go)     { |event| ... }
  on_before(:stop)  { |event| ... }
end
```

As the example demonstrates, by calling the `new` method on **FiniteMachine** you create an instance of finite state machine.

Having declared the states and transitions using `event` method, you can check current state:

```ruby
fm.current # => :red
````

And trigger transitions using the `trigger`:

```ruby
fm.trigger(:ready)
```

or direct method calls:

* `fm.ready`
* `fm.go`
* `fm.stop`

 The `events` and `callbacks` scopes help to define the behaviour of the machine. Read [States and Transitions](#3-states-and-transitions) and [Callbacks](#4-callbacks) sections for more details.

Alternatively, you can construct the state machine like a regular object without using the DSL methods. The same machine could be reimplemented as follows:

```ruby
fm = FiniteMachine.new(initial: :red)
fm.event(:ready, :red    => :yellow)
fm.event(:go,    :yellow => :green)
fm.event(:stop,  :green  => :red)
fm.on_before(:ready) { |event| ... }
fm.on_after(:go)     { |event| ... }
fm.on_before(:stop)  { |event| ...}
```

## 2. API

### 2.1 new

In most cases you will want to create an instance of **FiniteMachine** class using the `new` method. At the bare minimum you need specify the transition events inside a block using the `event` helper:

```ruby
fm = FiniteMachine.new do
  initial :green

  event :slow,  :green  => :yellow
  event :stop,  :yellow => :red
  event :ready, :red    => :yellow
  event :go,    :yellow => :green
end
```

Alternatively, you can skip block definition and instead call DSL methods directly on the state machine instance:

```ruby
fsm = FiniteMachine.new
fsm.initial(:green)
fsm.event(:slow, :green => :yellow)
fsm.event(:stop, :yellow => :red)
fsm.event(:ready,:red    => :yellow)
fsm.event(:go,   :yellow => :green)
```

As a guiding rule, any method exposed via DSL is available as a regular method call on the state machine instance.

### 2.2 define

To create a reusable definition for a state machine use `define` method. By calling `define` you're creating an anonymous class that can act as a factory for state machines. For example, below we create a 'TrafficLights' class that contains our state machine definition:

```ruby
TrafficLights = FiniteMachine.define do
  initial :green

  event :slow,  :green  => :yellow
  event :stop,  :yellow => :red
  event :ready, :red    => :yellow
  event :go,    :yellow => :green
end
```

Then you can create however many instance of above class:

```ruby
lights_fm_a = TrafficLights.new
lights_fm_b = TrafficLights.new
```

Each instance will start in consistent state:

```ruby
lights_fm_a.current # => :green
lights_fm_b.current # => :green
```

You can then trigger event in one instance and not the other:

```ruby
lights_fm_a.slow
lights_fm_a.current # => :yellow
lights_fm_b.current # => :green
```

### 2.3 current

The **FiniteMachine** allows you to query the current state by calling the `current` method.

```ruby
fm.current  # => :red
```

### 2.4 initial

There are number of ways to provide the initial state in  **FiniteMachine** depending on your requirements.

By default the **FiniteMachine** will be in the `:none` state and you will need to provide an explicit event to transition out of this state.

```ruby
fm = FiniteMachine.new do
  event :init,  :none   => :green
  event :slow,  :green  => :yellow
  event :stop,  :yellow => :red
end

fm.current # => :none
fm.init    # => true
fm.current # => :green
```

If you specify initial state using the `initial` helper, then the state machine will be created already in that state and an implicit `init` event will be created for you and automatically triggered upon the state machine initialization.

```ruby
fm = FiniteMachine.new do
  initial :green   # fires init event that transitions from :none to :green state

  event :slow,  :green  => :yellow
  event :stop,  :yellow => :red
end

fm.current # => :green
```

Or by passing named argument `:initial` like so:

```ruby
fm = FiniteMachine.new initial: :green do
  ...
end
```

If you want to defer setting the initial state, pass the `:defer` option to the `initial` helper. By default **FiniteMachine** will create `init` event that will allow to transition from `:none` state to the new state.

```ruby
fm = FiniteMachine.new do
  initial :green, defer: true # Defer calling :init event

  event :slow,  :green  => :yellow
  event :stop,  :yellow => :red
end
fm.current # => :none
fm.init    # execute initial transition
fm.current # => :green
```

If your target object already has `init` method or one of the events names renews `init`, you can use different name by passing `:event` option to `initial` helper.

```ruby
fm = FiniteMachine.new do
  initial :green, event: :start, defer: true # Rename event from :init to :start

  event :slow,  :green  => :yellow
  event :stop,  :yellow => :red
end

fm.current # => :none
fm.start   # => call the renamed event
fm.current # => :green
```

By default the `initial` does not trigger any callbacks. If you need to fire callbacks and any event associated actions on initial transition, pass the `silent` option set to `false` like so

```ruby
fm = FiniteMachine.new do
  initial :green, silent: false  # callbacks are triggered

  event :slow,  :green  => :yellow
  event :stop,  :yellow => :red
end
```

### 2.5 terminal

To specify a final state **FiniteMachine** uses the `terminal` method.

```ruby
fm = FiniteMachine.new do
  initial :green

  terminal :red

  event :slow, :green  => :yellow
  event :stop, :yellow => :red
  event :go,   :red    => :green
end
```

When the terminal state has been specified, you can use `terminated?` method on the state machine instance to verify if the terminal state has been reached or not.

```ruby
fm.terminated?  # => false
fm.slow         # => true
fm.terminated?  # => false
fm.stop         # => true
fm.terminated?  # => true
```

The `terminal` can accept more than one state.

```ruby
fm = FiniteMachine.new do
  initial :open

  terminal :close, :canceled

  event :resolve, :open => :close
  event :decline, :open => :canceled
end
```

And the terminal state can be checked using `terminated?`:

```ruby
fm.decline
fm.terminated?
```

### 2.6 is?

To verify whether or not a state machine is in a given state, **FiniteMachine** uses `is?` method. It returns `true` if the machine is found to be in the given state, or `false` otherwise.

```ruby
fm.is?(:red)    # => true
fm.is?(:yellow) # => false
```

Moreover, you can use helper methods to check for current state using the state name itself like so

```ruby
fm.red?     # => true
fm.yellow?  # => false
```

### 2.7 trigger

Transitions events can be fired by calling the `trigger` method with the event name and remaining arguments as data. The return value is either `true` or `false` depending whether the transition succeeded or not:

```ruby
fm.trigger(:ready) # => true
fm.trigger(:ready, 'one', 'two', 'three') # => true
```

By default the **FiniteMachine** automatically converts all the transition event names into methods:

```ruby
fm.ready # => true
fm.ready('one', 'two', 'three') # => true
```

Please see [States and Transitions](#3-states-and-transitions) for in-depth treatment of firing transitions.


#### 2.7.1 `:auto_methods`

By default all event names will be converted by **FiniteMachine** into method names. This also means that you won't be able to use event names such as `:fail` or `:trigger` as these are already defined on the machine instance. In situations when you wish to use any event name for your event names use `:auto_methods` keyword to disable automatic methods generation. For example, to define `:fail` event:


```ruby
fm = FiniteMachine.new(auto_methods: false) do
  initial :green

  event :fail, :green => :red
end
```

And then you can use `trigger` to fire the event:

```ruby
fm.trigger(:fail)
fm.current # => :red
```

### 2.8 `can?` and `cannot?`

To verify whether or not an event can be fired, **FiniteMachine** provides `can?` or `cannot?` methods. `can?` checks if **FiniteMachine** can fire a given event, returning `true`, otherwise, it will return `false`. The `cannot?` is simply the inverse of `can?`.

```ruby
fm.can?(:ready)    # => true
fm.can?(:go)       # => false
fm.cannot?(:ready) # => false
fm.cannot?(:go)    # => true
```

The `can?` and `cannot?` helper methods take into account the `:if` and `:unless` conditions applied to events. The set of values that `:if` or `:unless` condition takes as block parameter can be passed in directly via `can?` and `cannot?` methods' arguments, after the name of the event. For instance,

```ruby
fm = FiniteMachine.new do
  initial :green

  event :slow,  :green  => :yellow
  event :stop,  :yellow => :red, if: proc { |_, param| :breaks == param }
end

fm.can?(:slow) # => true
fm.can?(:stop) # => false

fm.slow                    # => true
fm.can?(:stop, :breaks)    # => true
fm.can?(:stop, :no_breaks) # => false
```

### 2.9 target

If you need to execute some external code in the context of the current state machine, pass that object as a first argument to `new` method.

Assuming we have a simple `Car` class that holds an internal state whether the car's engine is on or off:

```ruby
class Car
  def initialize
    @engine_on = false
  end

  def turn_engine_on
    @engine_on = true
  end

  def turn_engine_off
    @engine_on = false
  end

  def engine_on?
    @engine_on
  end
end
```

And given an instance of `Car` class:

```ruby
car = Car.new
```

You can provide a context to a state machine by passing it as a first argument to a `new` call. You can then reference this context inside the callbacks by calling the `target` helper:

```ruby
fm = FiniteMachine.new(car) do
  initial :neutral

  event :start, :neutral => :one, if: "engine_on?"
  event :stop,  :one => :neutral

  on_enter_start do |event| target.turn_engine_on end
  on_exit_start  do |event| target.turn_engine_off end
end
```

For more complex example see [Integration](#7-integration) section.

#### 2.9.1 `:alias_target`

If you wish to better express the intention behind the context object, in particular when calling actions in callbacks, you can use the `:alias_target` option:

```ruby
car = Car.new

fm = FiniteMachine.new(car, alias_target: :car) do
  initial :neutral

  event :start, :neutral => :one, if: "engine_on?"

  on_enter_start do |event| car.turn_engine_on end
  on_exit_start  do |event| car.turn_engine_off end
end
```

### 2.10 restore!

In order to set the machine to a given state and thus skip triggering callbacks use the `restore!` method:

```ruby
fm.restore!(:neutral)
```

This method may be suitable when used testing your state machine or in restoring the state from datastore.

### 2.11 states

You can use the `states` method to return an array of all the states for a given state machine.

```ruby
fm.states # => [:none, :green, :yellow, :red]
```

### 2.12 events

To find out all the event names supported by the state machine issue `events` method:

```ruby
fm.events # => [:init, :ready, :go, :stop]
```

## 3. States and Transitions

The **FiniteMachine** DSL exposes the `event` helper to define possible state transitions.

The `event` helper accepts as a first argument the transition's name which will later be used to create
method on the **FiniteMachine** instance. As a second argument the `event` accepts an arbitrary number of states either
in the form of `:from` and `:to` hash keys or by using the state names themselves as key value pairs.

```ruby
event :start, from: :neutral, to: :first
or
event :start, :neutral => :first
```

Once specified, the **FiniteMachine** will create custom methods for transitioning between each state.
The following methods trigger transitions for the example state machine.

* ready
* go
* stop

You can always opt out from automatic method generation by using [:auto_methods](#271-auto_methods) option.

### 3.1 Triggering transitions

In order to transition to the next reachable state, simply call the event's name on the **FiniteMachine** instance. If the transition succeeds the `true` value is returned, otherwise `false`.

```ruby
fm.ready         # => true
fm.current       # => :yellow
```

If you prefer you can also use `trigger` method to fire any event by its name:

```ruby
fm.trigger(:ready)  # => true
```

Furthermore, you can pass additional parameters with the method call that will be available in the triggered callback as well as used by any present guarding conditions.

```ruby
fm.go('Piotr!')  # => true
fm.current       # => :green
```

By default **FiniteMachine** will swallow all exceptions when and return `false` on failure. If you prefer to be notified when illegal transition occurs see [Dangerous transitions](#22-dangerous-transitions).

### 3.2 Dangerous transitions

When you declare event, for instance `ready`, the **FiniteMachine** will provide a dangerous version with a bang `ready!`. In the case when you attempt to perform illegal transition or **FiniteMachine** throws internal error, the state machine will propagate the errors. You can use handlers to decide how to handle errors on case by case basis see [6. Error Handling](#6-errors)

```ruby
fm.ready!  #  => raises FiniteMachine::InvalidStateError
```

If you prefer you can also use `trigger!` method to fire event:

```ruby
fm.trigger!(:ready)
```

### 3.3 Multiple from states

If an event transitions from multiple states to the same state then all the states can be grouped into an array.
Alternatively, you can create separate events under the same name for each transition that needs combining.

```ruby
fm = FiniteMachine.new do
  initial :neutral

  event :start,  :neutral             => :one
  event :shift,  :one                 => :two
  event :shift,  :two                 => :three
  event :shift,  :three               => :four
  event :slow,   [:one, :two, :three] => :one
end
```

### 3.4 `any_state` transitions

The **FiniteMachine** offers few ways to transition out of any state. This is particularly useful when the machine already defines many states.

You can use `any_state` as the name for a given state, for instance:

```ruby
event :run, from: any_state, to: :green

or

event :run, any_state => :green
```

Alternatively, you can skip the `any_state` call and just specify `to` state:

```ruby
event :run, to: :green
```

All the above `run` event definitions will always transition the state machine into `:green` state.

### 3.5 Collapsing transitions

Another way to specify state transitions under single event name is to group all your state transitions into a single hash like so:

```ruby
fm = FiniteMachine.define do
  initial :initial

  event :bump, :initial => :low,
                :low     => :medium,
                :medium  => :high
end
```

The same can be more naturally rewritten also as:

```ruby
fm = FiniteMachine.new do
  initial :initial

  event :bump, :initial => :low
  event :bump, :low     => :medium
  event :bump, :medium  => :high
end
```

### 3.6 Silent transitions

The **FiniteMachine** allows to selectively silence events and thus prevent any callbacks from firing. Using the `silent` option passed to event definition like so:

```ruby
fm = FiniteMachine.new do
  initial :yellow

  event :go    :yellow => :green, silent: true
  event :stop, :green => :red
end

fsm.go   # no callbacks
fms.stop # callbacks are fired
```

### 3.7 Logging transitions

To help debug your state machine, **FiniteMachine** provides `:log_transitions` option.

```ruby
FiniteMachine.new log_transitions: true do
  ...
end
```

### 3.8 Conditional transitions

Each event takes an optional `:if` and `:unless` options which act as a predicate for the transition. The `:if` and `:unless` can take a symbol, a string, a Proc or an array. Use `:if` option when you want to specify when the transition **should** happen. If you want to specify when the transition **should not** happen then use `:unless` option.

#### 3.8.1 Using a Proc

You can associate the `:if` and `:unless` options with a Proc object that will get called right before transition happens. Proc object gives you ability to write inline condition instead of separate method.

```ruby
fm = FiniteMachine.new do
  initial :green

  event :slow, :green => :yellow, if: -> { return false }
end

fm.slow    # doesn't transition to :yellow state
fm.current # => :green
```

Condition by default receives the current context, which is the current state machine instance, followed by extra arguments.

```ruby
fsm = FiniteMachine.new do
  initial :red

  event :go, :red => :green,
        if: -> (context, a) { context.current == a }
end

fm.go(:yellow) # doesn't transition
fm.go          # raises ArgumentError
```

**Note** If you specify condition with a given number of arguments then you need to call an event with the exact number of arguments, otherwise you will get `ArgumentError`. Thus in above scenario to prevent errors specify condition like so:

```ruby
if: -> (context, *args) { ... }
```

Provided your **FiniteMachine** is associated with another object through `target` helper. Then the target object together with event arguments will be passed to the `:if` or `:unless` condition scope.

```ruby
class Car
  attr_accessor :engine_on

  def turn_engine_on
    @engine_on = true
  end

  def turn_engine_off
    @engine_on = false
  end

  def engine_on?
    @engine_on
  end
end

car = Car.new
car.turn_engine_on

fm = FiniteMachine.new do
  initial :neutral

  target car

  event :start, :neutral => :one, if: -> (target, state) {
    target.engine_on = state
    target.engine_on?
  }
end

fm.start(false)
fm.current       # => :neutral
fm.start(true)
fm.current       # => :one
```

When the one-liner conditions are not enough for your needs, you can perform conditional logic inside the callbacks. See [4.9 Cancelling callbacks](#49-cancelling-inside-callbacks)

#### 3.8.2 Using a Symbol

You can also use a symbol corresponding to the name of a method that will get called right before transition happens.

```ruby
fsm = FiniteMachine.new do
  initial :neutral

  target car

  event :start, :neutral => :one, if: :engine_on?
end
```

#### 3.8.3 Using a String

Finally, it's possible to use string that will be evaluated using `eval` and needs to contain valid Ruby code. It should only be used when the string represents a short condition.

```ruby
fsm = FiniteMachine.new do
  initial :neutral

  target car

  event :start, :neutral => :one, if: "engine_on?"
end
```

#### 3.8.4 Combining transition conditions

When multiple conditions define whether or not a transition should happen, an Array can be used. Furthermore, you can apply both `:if` and `:unless` to the same transition.

```ruby
fsm = FiniteMachine.new do
  initial :green

  event :slow, :green => :yellow,
    if: [ -> { return true }, -> { return true} ],
    unless: -> { return true }
  event :stop, :yellow => :red
end
```

The transition only runs when all the `:if` conditions and none of the `unless` conditions are evaluated to `true`.

### 3.9 Choice pseudostates

Choice pseudostate allows you to implement conditional branch. The conditions of an event's transitions are evaluated in order to to select only one outgoing transition.

You can implement the conditional branch as ordinary events grouped under the same name and use familiar `:if/:unless` conditions:

```ruby
fsm = FiniteMachine.define do
  initial :green

  event :next, :green => :yellow, if: -> { false }
  event :next, :green => :red,    if: -> { true }
end

fsm.current # => :green
fsm.next
fsm.current # => :red
```

The same conditional logic can be implemented using much shorter and more descriptive style using `choice` method:

```ruby
fsm = FiniteMachine.new do
  initial :green

  event :next, from: :green do
    choice :yellow, if: -> { false }
    choice :red,    if: -> { true }
  end
end

fsm.current # => :green
fsm.next
fsm.current # => :red
```

#### 3.9.1 Dynamic choice conditions

Just as with event conditions you can make conditional logic dynamic and dependent on parameters passed in:

```ruby
fsm = FiniteMachine.new do
  initial :green

  event :next, from: :green do
    choice :yellow, if: -> (context, a) { a < 1 }
    choice :red,    if: -> (context, a) { a > 1 }
    default :red
  end
end

fsm.current # => :green
fsm.next(0)
fsm.current # => :yellow
```

If more than one of the conditions evaluates to true, a first matching one is chosen. If none of the conditions evaluate to true, then the `default` state is matched. However if default state is not present and non of the conditions match, no transition is performed. To avoid such situation always specify `default` choice.

#### 3.9.2 Multiple from states

Similarly to event definitions, you can specify the event to transition from a group of states:

```ruby
FiniteMachine.new do
  initial :red

  event :next, from: [:yellow, :red] do
    choice :pink, if: -> { false }
    choice :green
  end
end
```

or from any state using the `:any` state name like so:

```ruby
FiniteMachine.new do
  initial :red

  event :next, from: :any do
    choice :pink, if: -> { false }
    choice :green
  end
end
```

## 4. Callbacks

You can register a callback to listen for state transitions and events triggered, and based on these perform custom actions. There are five callbacks available in **FiniteMachine**:

* `on_before` - triggered before any transition
* `on_exit` - triggered when leaving any state
* `on_transition` - triggered during any transition
* `on_enter` - triggered when entering any state
* `on_after` - triggered after any transition

Use the state or event name as a first parameter to the callback helper followed by block with event argument and a list arguments that you expect to receive like so:

```ruby
on_enter :green { |event, a, b, c| ... }
```

When you subscribe to the `:green` state change, the callback will be called whenever someone triggers event that transitions in or out of that state. The same will happen on subscription to event `ready`, namely, the callback will be called each time the state transition method is triggered regardless of the states it transitions from or to.

```ruby
fm = FiniteMachine.new do
  initial :red

  event :ready, :red    => :yellow
  event :go,    :yellow => :green
  event :stop,  :green  => :red

  on_before :ready { |event, time1, time2, time3| puts "#{time1} #{time2} #{time3} Go!" }
  on_before :go    { |event, name| puts "Going fast #{name}" }
  on_before :stop  { |event| ... }
end

fm.ready(1, 2, 3)
fm.go('Piotr!')
```

**Note** Regardless of how the state is entered or exited, all the associated callbacks will be executed. This provides means for guaranteed initialization and cleanup.

### 4.1 on_(enter|transition|exit)

The `on_enter` callback is executed before given state change is fired. By passing state name you can narrow down the listener to only watch out for enter state changes. Otherwise, all enter state changes will be watched.

The `on_transition` callback is executed when given state change happens. By passing state name you can narrow down the listener to only watch out for transition state changes. Otherwise, all transition state changes will be watched.

The `on_exit` callback is executed after a given state change happens. By passing state name you can narrow down the listener to only watch out for exit state changes. Otherwise, all exit state changes will be watched.

### 4.2 on_(before|after)

The `on_before` callback is executed before a given event happens. By default it will listen out for all events, you can also listen out for specific events by passing event's name.

This callback is executed after a given event happened. By default it will listen out for all events, you can also listen out for specific events by passing event's name.

### 4.3 once_on

**FiniteMachine** allows you to listen on initial state change or when the event is fired first time by using the following 5 types of callbacks:

* `once_on_enter`
* `once_on_transition`
* `once_on_exit`
* `once_before`
* `once_after`

### 4.4 Execution sequence

Assuming we have the following event specified:

```ruby
event :go, :red => :yellow
```

Then by calling `go` event the following callbacks sequence will be executed:

* `on_before` - generic callback before `any` event
* `on_before :go` - callback before the `go` event
* `on_exit` - generic callback for exit from `any` state
* `on_exit :red` - callback for the `:red` state exit
* `on_transition` - callback for transition from `any` state to `any` state
* `on_transition :yellow` - callback for the `:red` to `:yellow` transition
* `on_enter` - generic callback for entry to `any` state
* `on_enter :yellow` - callback for the `:yellow` state entry
* `on_after` - generic callback after `any` event
* `on_after :go` - callback after the `go` event

### 4.5 Callback parameters

All callbacks as a first argument yielded to a block receive the `TransitionEvent` object with the following attributes:

* `name    # the event name`
* `from    # the state transitioning from`
* `to      # the state transitioning to`

followed by the rest of arguments that were passed to the event method.

```ruby
fm = FiniteMachine.new do
  initial :red

  event :ready, :red => :yellow

  on_enter_ready { |event, time|
    puts "lights switching from #{event.from} to #{event.to} in #{time} seconds"
  }
end

fm.ready(3)   #  => 'lights switching from red to yellow in 3 seconds'
```

### 4.6 Duplicate callbacks

You can define any number of the same kind of callback. These callbacks will be executed in the order they are specified.

```ruby
fm = FiniteMachine.new do
  initial :green

  event :slow, :green => :yellow

  on_enter(:yellow) { this_is_run_first }
  on_enter(:yellow) { then_this }
end
fm.slow # => will invoke both callbacks
```

### 4.7 Fluid callbacks

Callbacks can also be specified as full method calls.

```ruby
fm = FiniteMachine.define do
  initial :red

  event :ready, :red    => :yellow
  event :go,    :yellow => :green
  event :stop,  :green  => :red

  on_before_ready { |event| ... }
  on_before_go    { |event| ... }
  on_before_stop  { |event| ... }
end
```

### 4.8 Methods inside callbacks

Given a class `Car`:

```ruby
class Car
  attr_accessor :reverse_lights

  def turn_reverse_lights_off
    @reverse_lights = false
  end

  def turn_reverse_lights_on
    @reverse_lights = true
  end
end
```

We can easily manipulate state for an instance of a `Car` class:

```ruby
car = Car.new
```

By defining finite machine using the instance:

```ruby
fm = FiniteMachine.new(car) do
  initial :neutral

  event :forward, [:reverse, :neutral] => :one
  event :back,    [:neutral, :one] => :reverse

  on_enter_reverse { |event| target.turn_reverse_lights_on }
  on_exit_reverse  { |event| target.turn_reverse_lights_off }
end
```

Note that you can also fire events from callbacks.

```ruby
fm = FiniteMachine.new do
  initial :neutral

  event :forward, [:reverse, :neutral] => :one
  event :back,    [:neutral, :one] => :reverse

  on_enter_reverse { |event| forward('Piotr!') }
  on_exit_reverse  { |event, name| puts "Go #{name}" }
end
fm.back   # => Go Piotr!
```

For more complex example see [Integration](#7-integration) section.

### 4.9 Cancelling callbacks

A simple way to prevent transitions is to use [3 Conditional transitions](#3-conditional-transitions).

There are times when you want to cancel transition in a callback. For example, you have logic which allows transition to happen only under certain complex conditions. Using `cancel_event` inside the `on_(enter|transition|exit)` or `on_(before|after)` callbacks will stop all the callbacks from firing and prevent current transition from happening.

For example, firing any event will not move the current state:

```ruby
fm = FiniteMachine.new do
  initial :red

  event :ready, :red    => :yellow
  event :go,    :yellow => :green
  event :stop,  :green  => :red

  on_exit :red do |event|
    ...
    cancel_event
  end
end

fm.ready
fm.current  # => :red
```

### 4.10 Asynchronous callbacks

By default all callbacks are run synchronously. In order to add a callback that runs asynchronously, you need to pass second `:async` argument like so:

```ruby
  on_enter :green, :async do |event| ... end
```

Or

```ruby
  on_enter_green(:async) { |event| }
```

This will ensure that when the callback is fired it will run in separate thread outside of the main execution thread.


### 4.11 Instance callbacks

When defining callbacks you are not limited to the `callbacks` helper. After **FiniteMachine** instance is created you can register callbacks the same way as before by calling `on` and supplying the type of notification and state/event you are interested in.

```ruby
fm = FiniteMachine.new do
  initial :red

  event :ready, :red    => :yellow
  event :go,    :yellow => :green
  event :stop,  :green  => :red
end

fm.on_enter_yellow do |event|
  ...
end
```

## 5. Error Handling

By default, the **FiniteMachine** will throw an exception whenever the machine is in invalid state or fails to transition.

* `FiniteMachine::TransitionError`
* `FiniteMachine::InvalidStateError`
* `FiniteMachine::InvalidCallbackError`

You can attach specific error handler using the 'handle' with the name of the error as a first argument and a callback to be executed when the error happens. The `handle` receives a list of exception class or exception class names, and an option `:with` with a name of the method or a Proc object to be called to handle the error. As an alternative, you can pass a block.

```ruby
fm = FiniteMachine.new do
  initial :green, event: :start

  event :slow,  :green  => :yellow
  event :stop,  :yellow => :red

  handle FiniteMachine::InvalidStateError do |exception|
    # run some custom logging
    raise exception
  end

  handle FiniteMachine::TransitionError, with: proc { |exception| ... }
end
```

### 5.1 Using target

You can pass an external context as a first argument to the **FiniteMachine** initialization that will be available as context in the handler block or `:with` value. For example, the `log_error` method is made available when `:with` option key is used:

```ruby
class Logger
  def log_error(exception)
    puts "Exception : #{exception.message}"
  end
end

fm = FiniteMachine.new(logger) do
  initial :green

  event :slow, :green  => :yellow
  event :stop, :yellow => :red

  handle 'InvalidStateError', with: :log_error
end
```

## 6. Stand-alone

**FiniteMachine** allows you to separate your state machine from the target class so that you can keep your concerns broken in small maintainable pieces.

### 6.1 Creating a Definition

You can turn a class into a **FiniteMachine** by simply subclassing `FiniteMachine::Definition`. As a rule of thumb, every single public method of the **FiniteMachine** is available inside your class:

```ruby
class Engine < FiniteMachine::Definition
  initial :neutral

  event :forward, [:reverse, :neutral] => :one
  event :shift, :one => :two
  event :back,  [:neutral, :one] => :reverse

  on_enter :reverse do |event|
    target.turn_reverse_lights_on
  end

  on_exit :reverse do |event|
    target.turn_reverse_lights_off
  end

  handle FiniteMachine::InvalidStateError do |exception| ... end
end
```

### 6.2 Targeting definition

The next step is to instantiate your state machine and use a custom class instance to load specific context.

For example, having the following `Car` class:

```ruby
class Car
  def turn_reverse_lights_off
    @reverse_lights = false
  end

  def turn_reverse_lights_on
    @reverse_lights = true
  end

  def reverse_lights?
    @reverse_lights ||= false
  end
end
```

Thus, to associate `Engine` to `Car` do:

```ruby
car = Car.new
engine = Engine.new(car)

car.reverse_lignts?  # => false
engine.back
car.reverse_lights?  # => true
```

Alternatively, create method inside the `Car` that will do the integration like so

```ruby
class Car
  ... #  as above

  def engine
    @engine ||= Engine.new(self)
  end
end
```

### 6.3 Definition inheritance

You can create more specialised versions of a generic definition by using inheritance. Assuming a generic state machine definition:

```ruby
class GenericStateMachine < FiniteMachine::Definition
  initial :red

  event :start, :red => :green

  on_enter { |event| ... }
end
```

You can easily create a more specific definition that adds new events and more specific callbacks to the mix.

```ruby
class SpecificStateMachine < GenericStateMachine
  event :stop, :green => :yellow

  on_enter(:yellow) { |event| ... }
end
```

Finally to use the specific state machine definition do:

```ruby
specific_fsm = SpecificStateMachine.new
```

## 7. Integration

Since **FiniteMachine** is an object in its own right, it leaves integration with other systems up to you. In contrast to other Ruby libraries, it does not extend from models (i.e. ActiveRecord) to transform them into a state machine or require mixing into existing classes.

### 7.1 Plain Ruby Objects

In order to use **FiniteMachine** with an object, you need to define a method that will construct the state machine. You can implement the state machine using the `new` DSL or create a separate object that can be instantiated. To complete integration you will need to specify `target` context to allow state machine to communicate with the other methods inside the class like so:

```ruby
class Car
  def turn_reverse_lights_off
    @reverse_lights = false
  end

  def turn_reverse_lights_on
    @reverse_lights = true
  end

  def reverse_lights_on?
    @reverse_lights || false
  end

  def gears
    @gears ||= FiniteMachine.new(self) do
      initial :neutral

      event :start, :neutral => :one
      event :shift, :one => :two
      event :shift, :two => :one
      event :back,  [:neutral, :one] => :reverse

      on_enter :reverse do |event|
        target.turn_reverse_lights_on
      end

      on_exit :reverse do |event|
        target.turn_reverse_lights_off
      end

      on_transition do |event|
        puts "shifted from #{event.from} to #{event.to}"
      end
    end
  end
end
```

Having written the class, you can use it as follows:

```ruby
car = Car.new
car.gears.current      # => :neutral
car.reverse_lights_on? # => false

car.gears.start        # => "shifted from neutral to one"

car.gears.back         # => "shifted from one to reverse"
car.gears.current      # => :reverse
car.reverse_lights_on? # => true
```

### 7.2 ActiveRecord

In order to integrate **FiniteMachine** with ActiveRecord simply add a method with state machine definition. You can also define the state machine in separate module to aid reusability. Once the state machine is defined use the `target` helper to reference the current class. Having defined `target` you call ActiveRecord methods inside the callbacks to persist the state.

You can use the `restore!` method to specify which state the **FiniteMachine** should be put back into as follows:

```ruby
class Account < ActiveRecord::Base
  validates :state, presence: true

  before_validation :set_initial_state, on: :create

  def set_initial_state
    self.state = manage.current
  end

  after_find :restore_state
  after_initialize :restore_state

  def restore_state
    manage.restore!(state.to_sym) if state.present?
  end

  def manage
    @manage ||= FiniteMachine.new(self) do
      initial :unapproved

      event :enqueue, :unapproved => :pending
      event :authorize, :pending => :access

      on_enter do |event|
        target.state = state
      end
    end
  end
end

account = Account.new
account.state   # => :unapproved
account.manage.enqueue
account.state   # => :pending
account.manage.authorize
account.state   # => :access
```

Please note that you do not need to call `target.save` inside callback, it is enough to just set the state. It is much more preferable to let the `ActiveRecord` object to persist when it makes sense for the application and thus keep the state machine focused on managing the state transitions.

### 7.3 Transactions

When using **FiniteMachine** with ActiveRecord it advisable to trigger state changes inside transactions to ensure integrity of the database. Given Account example from section 7.2 one can run event in transaction in the following way:

```ruby
ActiveRecord::Base.transaction do
  account.manage.enqueue
end
```

If the transition fails it will raise `TransitionError` which will cause the transaction to rollback.

Please check the ORM of your choice if it supports database transactions.

## 8 Tips

Creating a standalone **FiniteMachine** brings a number of benefits, one of them being easier testing. This is especially true if the state machine is extremely complex itself. Ideally, you would test the machine in isolation and then integrate it with other objects or ORMs.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2014 Piotr Murach. See LICENSE for further details.
