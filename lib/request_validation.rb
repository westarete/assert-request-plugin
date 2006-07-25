
module RequestValidation

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
      required.delete!(param_requirements)
      
      # Continue to verify and eliminate all of the optional arguments
      optional = OptionalParams.new(required.params)
      optional.delete!(param_options)
      
      # There shouldn't be anything left
      unexpected = optional.params
      unless unexpected.empty?
        raise RequestError.new, "unexpected parameters: #{unexpected.inspect}"
      end
    rescue RequestError
      logger.error "Bad request: #{$!}" 
      logger.debug "  Method:"
      logger.debug "    permitted: #{valid_request_methods.inspect}"
      logger.debug "    actual:   #{request.method.inspect}"
      logger.debug "  Parameters:"
      logger.debug "    required: #{param_requirements.inspect}"
      logger.debug "    optional: #{param_options.inspect}"
      logger.debug "    actual:   #{original_params.inspect}"

      flash[:error] = @@flash_error_for_bad_request unless @@flash_error_for_bad_request.nil?
      redirect_to(@@redirect_for_bad_request) unless @@redirect_for_bad_request.nil?
      
      return false
    end  
    true
  end
  
private

  # The exception that we use to flag problems that we discover.
  class RequestError < RuntimeError ; end

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
          raise RequestError.new, "bad value for #{@key}: #{@value} is not an integer"
        end
      else
        unless @value == requirement
          raise RequestError.new, "bad value for #{@key}: #{@value} != '#{requirement}'"
        end
      end        
    end
  end
  
  # Represents the request method
  class RequestMethod
    
    def initialize(method)
      @method = method
    end
    
    # Check the request method against the given set of permissible methods.
    def validate(requirements)
      # Make sure we're dealing with an array
      unless requirements.respond_to? 'detect'
        requirements = [requirements]
      end 

      unless requirements.detect { |m| @method == m }
        raise RequestError.new, "request method #{@method} is not permitted"
      end      
    end
  end
  
  class RequiredParams
    attr_reader :params
    
    def initialize(params)
      @params = params.dup
    end

    # Remove our params that match the given requirements
    def delete!(requirements, parameters=@params)
      requirements.each do |key, requirement|
        value = parameters[key.to_s]
        if value.nil?
          raise RequestError.new, "missing parameter #{key}"
        end
        # Look for nested hashes
        if requirement.kind_of? Hash
          unless value.kind_of? Hash        
            raise RequestError.new, "parameter #{key} is not a compound value"
          end
          delete!(requirement, value)
          parameters.delete(key.to_s) if value.empty?
        else
          pair = ParameterPair.new(key, value)
          pair.validate(requirement)
          parameters.delete(key.to_s)
        end
      end
    end
    
  end # class RequiredParams
    
  class OptionalParams
    attr_reader :params
    
    def initialize(params)
      @params = params.dup
    end    
    
    # Remove our params that match the given requirements
    def delete!(requirements, parameters=@params)
      requirements.each do |key, requirement|
        value = parameters[key.to_s]
        next if value.nil?
        # Look for nested hashes
        if requirement.kind_of? Hash
          unless value.kind_of? Hash        
            raise RequestError.new, "parameter #{key} is not a compound value"
          end
          delete!(requirement, value)
          parameters.delete(key.to_s) if value.empty?
        else
          pair = ParameterPair.new(key, value)
          pair.validate(requirement)
          parameters.delete(key.to_s)
        end
      end
    end
    
  end # class OptionalParams
    
end # module RequestValidation
