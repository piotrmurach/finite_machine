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
