require 'parameter_pair'
require 'activerecord_requirement'
require 'request_error'

module ValidateRequest
  # An abstract class that describes how we generally treat sets of parameters
  # and their requirements.
  class AbstractParams
    attr_reader :params
    
    def initialize(params)
      @params = params.dup
    end

    # Remove our params that match the given requirements
    def validate_and_delete!(requirements, parameters=@params)
      requirements.each do |key, requirement|
        # Convert keys from symbols to strings, since that's how they appear
        # in the params hash.
        key = key.to_s
        
        # Look for this requirement in the given parameters. Let the child
        # class (optional vs. required) tell us what to do if it's missing.
        value = parameters[key]
        if value.nil?
          next if skip_missing_parameter?(key)
        end
        
        # If the requirement is an ActiveRecord class, expand it into a 
        # requirements hash of its content columns and their types. This 
        # effectively simulates the user having specified all of the model's
        # columns by hand using the standard hash notation.
        if ActiveRecordRequirement.is_model? requirement
          requirement = ActiveRecordRequirement.new(requirement).to_hash
        end
        
        if requirement.kind_of? Hash
          # Recursively verify nested hashes.
          unless value.kind_of? Hash        
            raise RequestError, "parameter '#{key}' is not a compound value"
          end
          validate_and_delete!(requirement, value)
          parameters.delete(key) if value.empty?
        else
          # Validate a normal key/value pair.
          ParameterPair.new(key, value).validate(requirement)
          parameters.delete(key)
        end
      end
    end
    
    protected

    # Child classes must implement this method, which determines how we 
    # behave in the face of a missing parameter compared to our requirements.
    def skip_missing_parameter?(key)
      raise "not implemented"
    end    
    
  end
end