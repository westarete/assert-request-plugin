# validate_request Rails Plugin
#
# (c) Copyright 2006 by West Arete Computing, Inc.

module ValidateRequest

protected
  # The URL where we should redirect if we get a bad request. Set to nil if
  # you do not want a redirect (and just test the return value of 
  # validate_request)
  @@redirect_for_bad_request = '/'
  
  # The message that should be put into flash[:error] if we should get a bad
  # request. Set to nil if you do not want flash[:error] to be set.
  @@flash_error_for_bad_request = 'Sorry, your last request could not be processed.'
  
  # Call this method at the beginning of your action to verify that the current
  # parameters match your idea of a valid set of values.
  def validate_request(valid_request_methods=:get, param_requirements={}, param_options={})
    # Remove the common parameters that are provided on each call, and don't
    # need to be declared to validate_request.
    original_params = params.dup
    [:action, :controller, :commit].each {|key| original_params.delete(key)}
    
    begin
      # Validate the request method.
      RequestMethod.new(request.method).validate(valid_request_methods)
      
      # Verify and eliminate all of the required arguments
      required = RequiredParams.new(original_params)
      required.validate_and_delete!(param_requirements)
      
      # Continue to verify and eliminate all of the optional arguments
      optional = OptionalParams.new(required.params)
      optional.validate_and_delete!(param_options)
      
      # There shouldn't be anything left
      unexpected = optional.params
      unless unexpected.empty?
        raise ValidateRequestError.new, "unexpected parameters: #{unexpected.inspect}"
      end
    rescue ValidateRequestError
      logger.error "Bad request: #{$!}" 
      logger.debug "  Method:"
      logger.debug "    permitted: #{valid_request_methods.inspect}"
      logger.debug "    actual:    #{request.method.inspect}"
      logger.debug "  Parameters:"
      logger.debug "    required:  #{param_requirements.inspect}"
      logger.debug "    optional:  #{param_options.inspect}"
      logger.debug "    actual:    #{original_params.inspect}"

      flash[:error] = @@flash_error_for_bad_request unless @@flash_error_for_bad_request.nil?
      redirect_to(@@redirect_for_bad_request) unless @@redirect_for_bad_request.nil?
      
      return false
    end  
    true
  end
  
private

  class ValidateRequestError < RuntimeError ; end

  # Represents one key/value parameter pair
  class ParameterPair
    attr_accessor :key, :value
  
    def initialize(key, value)
      @key, @value = key, value
    end

    # Check this parameter's value against the given type.
    def validate(requirement)
      # No real checking necessary for text or string
      return if requirement == :text or requirement == :string
      if requirement == :integer
        unless @value =~ /^\d+$/
          raise ValidateRequestError.new, "bad value for #{@key}: #{@value} is not an integer"
        end
      else
        unless @value == requirement
          raise ValidateRequestError.new, "bad value for #{@key}: #{@value} != '#{requirement}'"
        end
      end        
    end
  end
  
  # Defines how we handle and validate the request method.
  class RequestMethod
    
    def initialize(method)
      @method = method
    end
    
    # Check the request method against the given set of permissible methods.
    def validate(requirements)
      # Make sure we're dealing with an array
      requirements = [requirements] unless requirements.respond_to? 'detect'
      unless requirements.detect {|m| @method == m}
        raise ValidateRequestError.new, "request method #{@method} is not permitted"
      end      
    end
    
  end # class RequestMethod
  
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
            raise ValidateRequestError.new, "parameter '#{key}' is not a compound value"
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
    
  end # class AbstractParams
  
  # A child of AbstractParams that always requires that the parameters match
  # the requirements exactly.
  class RequiredParams < AbstractParams
  protected
    # We always raise an exception if we find a missing parameter.
    def skip_missing_parameter?(key)
      raise ValidateRequestError.new, "missing parameter '#{key}'"
    end        
  end
    
  # A child of AbstractParams that doesn't mind of some of the permitted 
  # parameters are missing from the actual parameters.
  class OptionalParams < AbstractParams
  protected
    # We always skip a missing parameter.
    def skip_missing_parameter?(key)
      true
    end
  end
    
end # module ValidateRequest
