
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
    @valid_request_methods = valid_request_methods
    @param_requirements    = param_requirements
    @param_options         = param_options

    # Make our own working copy of params, since we need to modify it.
    p = params.dup   
    
    # Remove the common parameters that are provided on each call, and don't
    # need to be declared.
    [:action, :controller, :commit].each {|key| p.delete(key)}
    
    # Preserve this clean copy of the params for logging later.
    @original_params = p.dup
      
    begin
      RequestMethod.new(request.method).validate(@valid_request_methods)
      process_required_parameters(@param_requirements, p)
      process_optional_parameters(@param_options, p)
    
      unless p.empty?
        raise RequestError.new, "unexpected parameters: #{p.inspect}"
      end
    rescue RequestError
      handle_bad_request
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
        
  # Proceess a set of requirements against the parameters
  def process_required_parameters(requirements, parameters)
    requirements.each do |key, requirement|
      value = parameters[key.to_s]
      if value.nil?
        raise RequestError.new, "missing parameter #{key.inspect}"
      end
      # Look for nested hashes
      if requirement.kind_of? Hash
        unless value.kind_of? Hash        
          raise RequestError.new, "parameter #{key.inspect} is not a compound value"
        end
        process_required_parameters(requirement, value)
        parameters.delete(key.to_s) if value.empty?
      else
        pair = ParameterPair.new(key, value)
        pair.validate(requirement)
        parameters.delete(key.to_s)
      end
    end
  end
    
  # Proceess a set of requirements against the parameters
  def process_optional_parameters(requirements, parameters)
    requirements.each do |key, requirement|
      value = parameters[key.to_s]
      next if value.nil?
      # Look for nested hashes
      if requirement.kind_of? Hash
        unless value.kind_of? Hash        
          raise RequestError.new, "parameter #{key.inspect} is not a compound value"
        end
        process_optional_parameters(requirement, value)
        parameters.delete(key.to_s) if value.empty?
      else
        pair = ParameterPair.new(key, value)
        pair.validate(requirement)
        parameters.delete(key.to_s)
      end
    end
  end
  
  # Give detailed log messages of the bad request, and redirect/set flash if
  # necessary.
  def handle_bad_request
    logger.error "Bad request: #{$!}" 
    logger.debug "  Method:"
    logger.debug "    permitted: #{@valid_request_methods.inspect}"
    logger.debug "    actual:   #{request.method.inspect}"
    logger.debug "  Parameters:"
    logger.debug "    required: #{@param_requirements.inspect}"
    logger.debug "    optional: #{@param_options.inspect}"
    logger.debug "    actual:   #{@original_params.inspect}"
    
    flash[:error] = @@flash_error_for_bad_request unless @@flash_error_for_bad_request.nil?
    redirect_to(@@redirect_for_bad_request) unless @@redirect_for_bad_request.nil?
  end    
  
end 
