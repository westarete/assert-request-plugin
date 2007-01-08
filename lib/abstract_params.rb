require 'parameter_pair'
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

        # Check for an index specification, e.g. :person => {[] => {:name => :string}
        if key.kind_of? Array
          unless key.empty?
            raise "Can't understand request specification: non-empty array for hash key: #{key.inspect}"
          end
          
          # Look for IDs in the params hash.
          index_params = parameters.select { |k,v| k =~ /^\d+$/ }
          if index_params.empty?
            next if skip_missing_parameter?(key)
          end
        
          # Validate each ID's value.
          index_params.each do |pkey, value|
            # Recursively verify nested hashes.
            unless value.kind_of? Hash
              raise RequestError, "parameter '#{pkey}' is not a compound value"
            end              
            validate_and_delete!(requirement, value)
            parameters.delete(pkey) if value.empty?
          end
        else
          
          # Look for this requirement in the given parameters. Let the child
          # class (optional vs. required) tell us what to do if it's missing.
          # Params hash uses strings (not symbols) for keys, so we convert.
          value = parameters[key.to_s]
          if value.nil?
            next if skip_missing_parameter?(key)
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
    end
    
    protected

    # Child classes must implement this method, which determines how we 
    # behave in the face of a missing parameter compared to our requirements.
    def skip_missing_parameter?(key)
      raise "not implemented"
    end    
        
  end
end