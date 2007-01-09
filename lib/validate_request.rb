# validate_request Rails Plugin
#
# (c) Copyright 2006 by West Arete Computing, Inc.

require 'request_rules'
require 'method_rules'
require 'protocol_rules'
require 'param_rules'
require 'required_param_rules'
require 'optional_param_rules'
require 'request_error'

module ValidateRequest

  # Call this method at the beginning of your action to verify that the current
  # parameters match your idea of a valid set of values.
  def assert_request(methods=[], requirements={}, options={}, protocols=[])
    if block_given?
      rules = RequestRules.new
      yield rules
    else
      rules = RequestRules.new(methods, requirements, options, protocols)
    end
    
    # Remove the common parameters that are provided on each call, and don't
    # need to be declared to validate_request.
    original_params = params.dup
    ParamRules.ignore_params.each {|key| original_params.delete(key)}
    
    # Validate the request method.
    MethodRules.new(request.method).validate(rules.methods)
    
    # Validate the request protocol.
    ProtocolRules.new(request.protocol).validate(rules.protocols)
    
    # Verify and eliminate all of the required arguments
    non_required = RequiredParamRules.new(rules.requirements).validate(original_params)
    
    # Continue to verify and eliminate all of the optional arguments
    unexpected = OptionalParamRules.new(rules.options).validate(non_required)
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
