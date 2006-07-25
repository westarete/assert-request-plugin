
module RequestValidation

protected
    
  # The URL where we should redirect if we get a bad request. Set to nil if
  # you do not want a redirect (and just test the return value of 
  # validate_request)
  @@redirect_for_bad_request = '/guide/list'
  
  # The message that should be put into flash[:error] if we should get a bad
  # request. Set to nil if you do not want flash[:error] to be set.
  @@flash_error_for_bad_request = 'Sorry, your last request could not be processed.'

  # Call this method at the beginning of your action to verify that the current
  # parameters match your idea of a valid set of values.
  #
  # For right now, we only support flat hashes for param_requirements and param_options.
  def validate_request(valid_request_methods=:get, param_requirements={}, param_options={})
    @valid_request_methods = valid_request_methods
    @param_requirements    = param_requirements
    @param_options         = param_options
    
    p = params.dup   # Keep our own copy of params, so that we can modify it.
    extract_standard_params(p)
    @original_params = p.dup
    
    validate_request_method or return false
    
    if @param_requirements.empty?
      return p.empty? ? true : handle_bad_params
    end
    
    @param_requirements.each do |key, requirement|
      value = p.delete(key.to_s)
      if value.nil?
        return handle_bad_params("missing argument #{key.inspect}")
      end
      validate_parameter(key, value, requirement) or return false
    end
    
    @param_options.each do |key, requirement|
      value = p.delete(key.to_s)
      next if value.nil?
      validate_parameter(key, value, requirement) or return false
    end
    
    unless p.empty?
      return handle_bad_params("found extra arguments: #{p.inspect}")
    end
    
    true
  end
  
private

  # Remove common parameters such as :action, :controller, and :commmit from 
  # the given hash and return them.
  def extract_standard_params(p)
    standard_params = {}
    [:action, :controller, :commit].each do |key|
      standard_params[key] = p.delete(key)
    end
    standard_params
  end

  # Ensure that the current request is via one of the given methods.
  def validate_request_method
    # Make sure we're dealing with an array
    unless @valid_request_methods.respond_to? 'detect'
      @valid_request_methods = [@valid_request_methods]
    end 

    if @valid_request_methods.detect { |m| request.method == m }
      true
    else
      logger.error "Bad request method: permitted #{@valid_request_methods.inspect}, but got #{request.method.inspect}"
      handle_bad_request
    end
  end
  
  # Take care of the case where we've found a bad parameter
  def handle_bad_params(message=nil)
    logger.error "Bad parameters: #{message}" unless message.nil? or message.empty?
    logger.error "Bad parameters:\n  required: #{@param_requirements.inspect},\n  optional: #{@param_options.inspect},\n  actual: #{@original_params.inspect}"
    handle_bad_request
  end
  
  # Set the flash and redirect for a bad request.
  def handle_bad_request
    flash[:error] = @@flash_error_for_bad_request unless @@flash_error_for_bad_request.nil?
    redirect_to(@@redirect_for_bad_request) unless @@redirect_for_bad_request.nil?
    false    
  end
  
  # Check a given key/value pair against its requirement. 
  def validate_parameter(name, value, requirement)
    # Check parameter's type
    if requirement == :integer
      unless value =~ /^\d+$/
        return handle_bad_params("#{name}'s value is not an integer")
      end
    elsif requirement == :text or requirement == :string
      # No real checking that we can do
    else
      unless value == requirement
        return handle_bad_params("#{value} != '#{requirement}'")
      end
    end        
    true
  end    
      
end 
