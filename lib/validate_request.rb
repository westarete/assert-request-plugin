# validate_request Rails Plugin
#
# (c) Copyright 2006 by West Arete Computing, Inc.

require 'request_rules'
require 'request_method'
require 'required_params'
require 'optional_params'
require 'request_error'

module ValidateRequest

  # Call this method at the beginning of your action to verify that the current
  # parameters match your idea of a valid set of values.
  def assert_valid_request(methods=:get, requirements={}, options={})
    if block_given?
      rules = RequestRules.new
      yield rules
    else
      rules = RequestRules.new(methods, requirements, options)
    end
    
    # Remove the common parameters that are provided on each call, and don't
    # need to be declared to validate_request.
    original_params = params.dup
    [:action, :controller, :commit].each {|key| original_params.delete(key)}
    
    # Validate the request method.
    RequestMethod.new(request.method).validate(rules.methods)
    
    # Verify and eliminate all of the required arguments
    required = RequiredParams.new(original_params)
    required.validate_and_delete!(rules.requirements)
    
    # Continue to verify and eliminate all of the optional arguments
    optional = OptionalParams.new(required.params)
    optional.validate_and_delete!(rules.options)
    
    # There shouldn't be anything left
    unexpected = optional.params
    unless unexpected.empty?
      raise RequestError, "unexpected parameters: #{unexpected.inspect}"
    end
    
    true
  rescue RequestError
    # Temporarily intercept the exception here so that we can log the details.
    logger.error "Bad request: #{$!}" 
    logger.debug "  Method:"
    logger.debug "    permitted: #{rules.methods.inspect}"
    logger.debug "    actual:    #{request.method.inspect}"
    logger.debug "  Parameters:"
    logger.debug "    required:  #{rules.requirements.inspect}"
    logger.debug "    optional:  #{rules.options.inspect}"
    logger.debug "    actual:    #{original_params.inspect}"
    raise
  end
    
end
