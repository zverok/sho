# frozen_string_literal: true

module Sho
  class ArgumentValidator
    def initialize(*mandatory, **optional)
      mandatory.all? { |m| m.is_a?(Symbol) } or
        fail ArgumentError, 'Mandatory arguments should be send as array of symbols'
      @mandatory = mandatory
      @optional = optional
    end

    def call(**params)
      guard_missing!(params)
      guard_unknown!(params)
      params.merge(@optional.reject { |key,| params.key?(key) })
    end

    private

    def guard_missing!(**params)
      (@mandatory - params.keys).tap do |missing|
        missing.empty? or fail ArgumentError, "missing keywords: #{missing.join(', ')}"
      end
    end

    def guard_unknown!(**params)
      (params.keys - @mandatory - @optional.keys).tap do |unknown|
        unknown.empty? or fail ArgumentError, "unknown keywords: #{unknown.join(', ')}"
      end
    end
  end
end
