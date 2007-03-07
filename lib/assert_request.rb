# assert_request Rails Plugin
#
# (c) Copyright 2006 by West Arete Computing, Inc.

require 'request_rules'
require 'method_rules'
require 'protocol_rules'
require 'param_rules'
require 'required_param_rules'
require 'optional_param_rules'
require 'request_error'

module AssertRequest

  # Call this method at the beginning of your action to verify that the current
  # parameters match your idea of a valid set of values.
  def assert_request(methods=[], requirements={}, options={}, protocols=[])
    # Collect the requirements via the given block.
    rules = RequestRules.new
    yield rules
    
    # Parse the initial requirements into the sets of rules. We do this first
    # so that we can report completely on the requirements in case of an
    # exception during validation.
    method_rules          = MethodRules.new(rules.methods)
    protocol_rules        = ProtocolRules.new(rules.protocols)
    required_params_rules = RequiredParamRules.new(rules.requirements)
    optional_params_rules = OptionalParamRules.new(rules.options)

    # Validate each part of the request.
    method_rules.validate(request.method)
    protocol_rules.validate(request.protocol)
    # Verify and eliminate all of the required arguments
    non_required = required_params_rules.validate(params)    
    # Continue to verify and eliminate all of the optional arguments
    unexpected = optional_params_rules.validate(non_required)
    # Anything left over is unexpected.
    unless unexpected.empty?
      raise RequestError, "unexpected params: #{unexpected.inspect}"
    end
    
    true
  rescue RequestError
    # Temporarily intercept the exception here so that we can log the details.
    logger.error "Bad request: #{$!}" 
    logger.debug "  Method:"
    logger.debug "    permitted: #{method_rules.requirements.inspect}"
    logger.debug "    actual:    #{request.method}"
    logger.debug "  Protocol:"
    logger.debug "    permitted: #{protocol_rules.requirements.inspect}"
    logger.debug "    actual:    #{request.protocol}"
    logger.debug "  Parameters:"
    logger.debug "    required:  #{required_params_rules.requirements.inspect}"
    logger.debug "    optional:  #{optional_params_rules.requirements.inspect}"
    logger.debug "    ignored:   #{ParamRules.ignore_params.inspect}"
    logger.debug "    actual:    #{params.inspect}"
    raise
  end
    
end
