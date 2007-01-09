require 'param_pair_rules'
require 'request_error'

module ValidateRequest
  
  # An abstract class that describes how we generally treat sets of parameters
  # and their requirements. Child classes must implement the 
  # skip_missing_parameter? method, which determines how we behave in the face 
  # of a missing parameter compared to our requirements.
  class ParamRules #:nodoc:
    attr_reader :requirements
    
    # The set of params that we should ignore by default. You could modify 
    # this in your environment.rb if its default settings don't suit your 
    # appliction. 
    @@ignore_params = %w( action controller commit method )
    
    # I had to define the cattr_accessor methods myself, since I kept getting
    # an error that cattr_accessor was not defined. Couldn't solve it the 
    # right way.
    def self.ignore_params
      @@ignore_params
    end
    
    def self.ignore_params=(new_value)
      @@ignore_params = new_value
    end

    def initialize(requirements)
      @requirements = requirements.dup
    end

    # Validate the given parameters against our requirements, raising 
    # exceptions for bad parameters, and returning a hash of any unrecognized
    # params.
    def validate(params)
      returning params.dup do |copy_of_params|
        validate_and_delete!(@requirements, copy_of_params)
      end
    end
    
    protected
    
    # Validate the given parameters against the given requirements, raising 
    # exceptions for bad parameters, and deleting valid parameters from the
    # given parameters hash.
    def validate_and_delete!(requirements, params)  
      requirements.each do |requirement_key, requirement_value|
        if requirement_key.kind_of? Array
          validate_and_delete_collection!(requirement_key, requirement_value, params)
        else
          validate_and_delete_variable!(requirement_key, requirement_value, params)
        end
      end
    end
    
    # Validate a collection, for example one that was specified like:
    #   [] => {'name' => :string}
    # The requirement_key is (should be) the empty array. The
    # requirement_value is the hash of requirements ({'name' => :string in 
    # this case). And the params hash is what to validate. Raises exceptions 
    # for bad parameters, and deletes valid parameters from the params hash.
    def validate_and_delete_collection!(requirement_key, requirement_value, params)
      unless requirement_key.empty?
        raise "Can't understand request specification: non-empty array for hash requirement_key: #{requirement_key.inspect}"
      end
      
      # Look for IDs in the params hash.
      index_params = params.select { |k,v| k =~ /^\d+$/ }
      
      # We're supposed to be a collection. If there are no indexes in the 
      # params hash, then we count this variable as "missing".
      return if index_params.empty? and skip_missing_parameter?(requirement_key)
    
      # Recursively validate each ID's value, which must be a hash.
      index_params.each do |params_key, params_value|
        validate_and_delete_hash!(params_key, requirement_value, params_value)
        params.delete(params_key) if params_value.empty?
      end
    end
    
    # Validate a variable requirement for the given params. Raises exceptions 
    # for bad parameters, and deletes valid parameters from the params hash.
    def validate_and_delete_variable!(requirement_key, requirement_value, params)
      # Look for this requirement_value in the given params. We convert 
      # symbols to strings for the user's convenience (params are always 
      # strings).
      params_value = params[requirement_key.to_s]
      return if params_value.nil? and skip_missing_parameter?(requirement_key)
    
      if requirement_value.kind_of? Hash
        # Recursively verify nested hashes.
        validate_and_delete_hash!(requirement_key, requirement_value, params_value)
        params.delete(requirement_key) if params_value.empty?
      else
        # Validate a normal requirement_key/value pair.
        ParamPairRules.new(requirement_key, params_value).validate(requirement_value)
        params.delete(requirement_key)
      end    
    end
    
    # Validate the given params value against the given requirement_value,
    # presuming that requirement_value is a hash.
    # Raises exceptions for bad parameters, and deletes valid parameters from 
    # the given params value, which should also be a hash.
    def validate_and_delete_hash!(requirement_key, requirement_value, params)
      unless params.kind_of? Hash        
        raise RequestError, "parameter '#{requirement_key}' is not a compound value"
      end
      validate_and_delete!(requirement_value, params)
    end

  end
end