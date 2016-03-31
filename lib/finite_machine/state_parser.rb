# encoding: utf-8

module FiniteMachine
  # A class responsible for converting transition arguments to states
  #
  # Used by {TransitionBuilder} to parse user input state transitions.
  #
  # @api private
  class StateParser
    BLACKLIST = [:name, :if, :unless, :silent].freeze

    # Initialize a StateParser
    #
    # @example
    #   StateParpser.new({from: [:green, :blue], to: :red})
    #
    # @param [Hash] attrs
    #
    # @api public
    def initialize(attrs)
      @attrs = ensure_only_states!(attrs)
      freeze
    end

    # Extract states from attributes
    #
    # @param [Proc] block
    #
    # @example
    #   StateParpser.new(attr).parase_states
    #
    # @yield [Hash[Symbol]] the resolved states
    #
    # @return [Hash[Symbol]] the resolved states
    #
    # @api public
    def parse(&block)
      states = extract_states
      block ? states.each(&block) : states
    end

    # Check if attributes contain :from or :to key
    #
    # @example
    #   parser = StateParser.new({from: :green, to: :red})
    #   parser.contains_from_to_keys?   # => true
    #
    # @example
    #   parser = StateParser.new({:green => :red})
    #   parser.contains_from_to_keys?   # => false
    #
    # @return [Boolean]
    #
    # @api public
    def contains_from_to_keys?
      [:from, :to].any? { |key| @attrs.keys.include?(key) }
    end

    # Return parser attributes
    #
    # @return [String]
    #
    # @api public
    def to_s
      @attrs.to_s
    end

    # Return string representation
    #
    # @return [String]
    #
    # @api public
    def inspect
      attributes = @attrs.map { |k, v| "#{k}:#{v}" }.join(', ')
      "<##{self.class} @attrs=#{attributes}>"
    end

    private

    # Extract only states from attributes
    #
    # @return [Hash[Symbol]]
    #
    # @api private
    def ensure_only_states!(attrs)
      attributes = attrs.dup
      BLACKLIST.each { |key| attributes.delete(key) }
      raise_not_enough_transitions unless attributes.any?
      attributes
    end

    # Convert attrbiutes with :from, :to keys to states hash
    #
    # @return [Hash[Symbol]]
    #
    # @api private
    def convert_from_to_attributes_to_states_hash
      Array(@attrs[:from] || ANY_STATE).reduce({}) do |hash, state|
        hash[state] = @attrs[:to] || state
        hash
      end
    end

    # Convert collapsed attributes to states hash
    #
    # @example
    #   parser = StateParser.new([:green, :red] => :yellow)
    #   parser.parse # => {green: :yellow, red: :yellow}
    #
    # @return [Hash[Symbol]]
    #
    # @api private
    def convert_attributes_to_states_hash
      @attrs.reduce({}) do |hash, (k, v)|
        if k.respond_to?(:to_ary)
          k.each { |el| hash[el] = v }
        else
          hash[k] = v
        end
        hash
      end
    end

    # Perform extraction of states from user supplied definitions
    #
    # @return [Hash[Symbol]] the resolved states
    #
    # @api private
    def extract_states
      if contains_from_to_keys?
        convert_from_to_attributes_to_states_hash
      else
        convert_attributes_to_states_hash
      end
    end

    # Raise error when not enough transitions are provided
    #
    # @raise [NotEnoughTransitionsError]
    #   if the event has no transitions
    #
    # @return [nil]
    #
    # @api private
    def raise_not_enough_transitions
      fail NotEnoughTransitionsError, 'please provide state transitions'
    end
  end # StateParser
end # FiniteMachine
