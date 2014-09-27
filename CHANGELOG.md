0.9.2 (September 27, 2014)

* Removes use of class variable to share Sync by @reggieb
* Fix observer to differentiate between any state and any event
* [#23] Fix transition to correctly set :from and :to parameters for :any state
* [#25] Fix passing parameters to choice events with same named events
* Fix choice pseudostate to work with :any state

0.9.1 (August 10, 2014)

* Add TransitionBuilder to internally build transitions from states
* Fix #choice to allow for multiple from states
* Add #current? to Transition to determine if matches from state
* Add #select_choice_transition to EventsChain to determine matching choice transition
* Fix #choice to work with same named events

0.9.0 (August 3, 2014)

* Add Definition class to allow to define standalone state machine
* Upgrade RSpec dependency and refactor specs
* Change initial helper to simply state name with options
* Change HookEvent to be immutable and extend comparison
* Change Event to be immutable and extend comparison
* Add #build method to HookEvent
* Change finished? to terminated? and allow for multiple terminal states
* Change to require explicit context to call target methods

0.8.1 (July 5, 2014)

* Add EventsChain to handle internal events logic
* Add EventBuilder to handle events construction

0.8.0 (June 22, 2014)

* Add silent option for state machine events to allow turning on/off
  selectively callbacks
* Ensure that can? & cannot? take into account conditionl logic applied
  to transitions
* Add restore! method to allow to set the state directly without callbacks
* Add ability to do dynamic conditional branching using the choice DSL or
  grouped events with different outgoing transitions [solves #13 and #6 issue]

0.7.1 (June 8, 2014)

* Change to relax callback name checks to allow for duplicate state and event names
* Change so that transition to initial state triggers callbacks

0.7.0 (May 26, 2014)

* Change Event to EventHook for callback events
* Add Event to hold the logic for event specification
* Fix issue #8 to preserve conditionals between event specifications
* Change to allow for self-transition - fixes issue #9
* Change to detect attempt to overwrite already defined method - fixes issue #10
* Fix #respond_to on state machine to include observer
* Add string inspection to hooks
* Fix observer missing methods resolution
* Change to separate state and event callbacks. Introduced on_enter, on_before,
  once_on_enter, once_on_before new event callbacks.
* Change generic callbacks to default to any state for on_enter, on_transition,
  on_exit and any event for on_before and on_after
* Add check for callback name conflicts
* Ensure proper callback lifecycle

0.6.1 (May 10, 2014)

* Fix stdlib requirement

0.6.0 (May 10, 2014)

* Add StateParser to allow for grouping transition under same event name
* Change Transition to store a map of transition for a given event
* Add abilility to correctly extract :to state for Transition instance
* Fix bug #6 with incorrect TransitionEvent payload information

0.5.0 (April 28, 2014)

* Change to allow for machine to be constructed as plain object
* Allow for :initial, :terminal and :target to be machine parameters
* Add generic Listener interface
* Change EventQueue to allow for subscription
* Increase test coverage to 98%
* Change to allow access to target inside machine dsl
* Add ability to fire callbacks asynchronously
* Add initial state storage

0.4.0 (April 13, 2014)

* Change initial state to stop firing event notification
* Fix initial to accept any state object
* Add logger
* Add ability to cancel transitions inside callbacks
* Fix proc conditions to accept aditional arguments
* Increase test coverage to 97%
* Add ability to force transitions

0.3.0 (March 30, 2014)

* Move development dependencies to Gemfile
* Increase test coverage to 95%
* Fix bug with event methods dynamic redefinition
* Change attr_threadsafe to accept default values
* Fix observer respond_to
* Add ability to specify callbacks on machine instance
* Add once_on type of callback
* Add off method for removing callbacks
* Add async method to state_machine for asynchronous events firing
* Fix Callable to correctly forward arguments
* Add state helpers fsm.green? to allow easily check current state

0.2.0 (March 01, 2014)

* Ensure correct transition object state
* Add methods synchronization for thread safety
* Fix bug - callback event object returns correct from state
* Add ability to define custom initial event
* Add hooks class for callbacks registration
* Extend threadable accessors
* Add generic state and event listeners
* Add target to allow integration with external objects,
  and allow easy method lookup through callback context
* Add ability to specify custom handlers for error conditions
