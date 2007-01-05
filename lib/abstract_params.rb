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
        # Convert keys from symbols to strings, since that's how they appear
        # in the params hash.
        key = key.to_s

        value = parameters[key]
        if value.nil?
          next if skip_missing_parameter?(key)
        end
        
        # If the requirement is an ActiveRecord class, expand it into a 
        # requirements hash of its content columns and their types.
        if is_model? requirement
          requirement = expand_active_record_to_hash_requirement(requirement)
        end
        
        if requirement.kind_of? Hash
          unless value.kind_of? Hash        
            raise RequestError, "parameter '#{key}' is not a compound value"
          end
          validate_and_delete!(requirement, value)
          parameters.delete(key) if value.empty?
        else
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

    private
    
    # Determine if the given requirement is an ActiveRecord model.
    def is_model?(requirement)
      requirement.respond_to? :ancestors and
        requirement.ancestors.detect {|a| a == ActiveRecord::Base}
    end
    
    # Pick out the desired content columns from the given activerecord class.
    def validate_columns(klass)
      ignore = %w( created_at updated_at created_on updated_on created_by updated_by )
      columns = []
      klass.content_columns.each do |column|
        columns << column unless ignore.detect {|name| name == column.name }
      end
      columns
    end

    # Expand the given ActiveRecord::Base class into a requirements hash of 
    # its content columns and their types.
    def expand_active_record_to_hash_requirement(klass)
      requirements = {}
      validate_columns(klass).each do |column|
        # For right now, we only support integer and text.
        requirements[column.name] = (column.type == :integer) ? :integer : :text
      end
      requirements
    end
    
  end
end