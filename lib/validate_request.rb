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
    
    # Validate the request method.
    MethodRules.new(rules.methods).validate(request.method)
    
    # Validate the request protocol.
    ProtocolRules.new(rules.protocols).validate(request.protocol)
    
    # Verify and eliminate all of the required arguments
    non_required = RequiredParamRules.new(rules.requirements).validate(params)
    
    # Continue to verify and eliminate all of the optional arguments
    unexpected = OptionalParamRules.new(rules.options).validate(non_required)
    
    # Anything left over is unexpected.
    unless unexpected.empty?
      raise RequestError, "unexpected parameters: #{unexpected.inspect}"
    end
    
    true
  rescue RequestError
    # Temporarily intercept the exception here so that we can log the details.
    logger.error "Bad request: #{$!}" 
    logger.debug "  Method:"
    logger.debug "    permitted: #{rules.methods.inspect}"
    logger.debug "    actual:    #{request.method}"
    logger.debug "  Protocol:"
    logger.debug "    permitted: #{rules.protocols.inspect}"
    logger.debug "    actual:    #{request.protocol}"
    logger.debug "  Parameters:"
    logger.debug "    required:  #{rules.requirements.inspect}"
    logger.debug "    optional:  #{rules.options.inspect}"
    logger.debug "    ignored:   #{ParamRules.ignore_params.inspect}"
    logger.debug "    actual:    #{params.inspect}"
    raise
  end
    
end
