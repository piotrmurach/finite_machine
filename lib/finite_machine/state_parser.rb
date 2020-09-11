# frozen_string_literal: true

module FiniteMachine
  # A class responsible for converting transition arguments to states
  #
  # Used by {TransitionBuilder} to parse user input state transitions.
  #
  # @api private
  class StateParser
    NON_STATE_KEYS = %i[name if unless silent].freeze

    STATE_KEYS = %i[from to].freeze

    # Extract states from user defined attributes
    #
    # @example
    #   StateParser.parse({from: [:green, :blue], to: :red})
    #   # => {green: :red, green: :blue}
    #
    # @param [Proc] block
    #
    # @yield [Hash[Symbol]] the resolved states
    #
    # @return [Hash[Symbol]] the resolved states
    #
    # @api public
    def self.parse(attributes, &block)
      attrs  = ensure_only_states!(attributes)
      states = extract_states(attrs)
      block ? states.each(&block) : states
    end

    # Extract only states from attributes
    #
    # @return [Hash[Symbol]]
    #
    # @api private
    def self.ensure_only_states!(attrs)
      attributes = attrs.dup
      NON_STATE_KEYS.each { |key| attributes.delete(key) }
      raise_not_enough_transitions unless attributes.any?
      attributes
    end
    private_class_method :ensure_only_states!

    # Perform extraction of states from user supplied definitions
    #
    # @return [Hash[Symbol]] the resolved states
    #
    # @api private
    def self.extract_states(attrs)
      if contains_from_to_keys?(attrs)
        convert_from_to_attributes_to_states_hash(attrs)
      else
        convert_attributes_to_states_hash(attrs)
      end
    end
    private_class_method :extract_states

    # Check if attributes contain :from or :to key
    #
    # @example
    #   StateParser.contains_from_to_keys?({from: :green, to: :red})
    #   # => true
    #
    # @example
    #   StateParser.contains_from_to_keys?({:green => :red})
    #   # => false
    #
    # @return [Boolean]
    #
    # @api public
    def self.contains_from_to_keys?(attrs)
      STATE_KEYS.any? { |key| attrs.keys.include?(key) }
    end
    private_class_method :contains_from_to_keys?

    # Convert attrbiutes with :from, :to keys to states hash
    #
    # @return [Hash[Symbol]]
    #
    # @api private
    def self.convert_from_to_attributes_to_states_hash(attrs)
      Array(attrs[:from] || ANY_STATE).reduce({}) do |hash, state|
        hash[state] = attrs[:to] || state
        hash
      end
    end
    private_class_method :convert_from_to_attributes_to_states_hash

    # Convert collapsed attributes to states hash
    #
    # @example
    #   StateParser.convert_attributes_to_states_hash([:green, :red] => :yellow)
    #   # => {green: :yellow, red: :yellow}
    #
    # @param [Hash] attrs
    #   the attributes to convert to a simple hash
    #
    # @return [Hash[Symbol]]
    #
    # @api private
    def self.convert_attributes_to_states_hash(attrs)
      attrs.reduce({}) do |hash, (k, v)|
        if k.respond_to?(:to_ary)
          k.each { |el| hash[el] = v }
        else
          hash[k] = v
        end
        hash
      end
    end
    private_class_method :convert_attributes_to_states_hash

    # Raise error when not enough transitions are provided
    #
    # @raise [NotEnoughTransitionsError]
    #   if the event has no transitions
    #
    # @return [nil]
    #
    # @api private
    def self.raise_not_enough_transitions
      raise NotEnoughTransitionsError, 'please provide state transitions'
    end
    private_class_method :raise_not_enough_transitions
  end # StateParser
end # FiniteMachine
