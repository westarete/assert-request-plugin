# assert_request Rails Plugin
#
# (c) Copyright 2006 by West Arete Computing, Inc.

require 'request_rules'
require 'method_rules'
require 'protocol_rules'
require 'param_rules'
require 'request_error'

module AssertRequest

  # Call this method at the beginning of your action to verify that the current
  # parameters match your idea of a valid set of values.
  def assert_request
    # Collect the requirements via the given block.
    rules = RequestRules.new
    yield rules
        
    # Parse the initial requirements and validate each part of the request.
    MethodRules.new(rules.methods).validate(request.method)
    ProtocolRules.new(rules.protocols).validate(request.protocol)
    rules.params.validate(params)    
  rescue RequestError
    # Temporarily intercept the exception here so that we can log the details.
    logger.error "Bad request: #{$!}" 
    raise
  end
    
end
