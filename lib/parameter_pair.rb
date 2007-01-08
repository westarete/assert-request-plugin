require 'request_error'

module ValidateRequest
  # Represents one key/value parameter pair
  class ParameterPair #:nodoc:
    attr_accessor :key, :value
  
    def initialize(key, value)
      @key, @value = key, value
    end

    # Check this parameter's value against the given type.
    def validate(requirement)
      # No real checking necessary for text or string
      return if requirement == :text or requirement == :string
      if requirement == :integer
        unless @value.to_s =~ /^\d+$/
          raise RequestError, "bad value for #{@key}: #{@value} is not an integer"
        end
      elsif requirement.respond_to? :detect
        unless requirement.detect { |r| r == @value }
          raise RequestError, "bad value for #{@key}: #{@value} != '#{requirement.inspect}'"
        end
      else
        unless @value == requirement
          raise RequestError, "bad value for #{@key}: #{@value} != '#{requirement}'"
        end
      end        
    end
  end
end