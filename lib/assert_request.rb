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

  # Only checks the params hash for the given elements. Ignores any other 
  # elements in params. This allows you to specify a minimum requirement for 
  # the params without having to specify all the optional elements. Example:
  # 
  #   assert_params_must_have :id, :name
  # 
  # In a way, this is similar to:
  # 
  #   assert_request { |r| r.params.must_have :id, :name }
  # 
  # however the latter will complain if there are any elements other than :id
  # and :name in the params hash, whereas the previous will not.
  #   
  def assert_params_must_have(*args, &block)
    param_rules = ParamRules.new(nil, nil, true, true)
    param_rules.must_have(*args, &block)
    param_rules.validate(params)
  rescue RequestError
    # Temporarily intercept the exception here so that we can log the details.
    logger.error "Bad request: #{$!}" 
    raise
  end    
    
end
