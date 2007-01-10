require 'param_rules'

module ValidateRequest
  # A child of ParamRules that always requires that the parameters match
  # the requirements exactly.
  class RequiredParamRules < ParamRules #:nodoc:
    protected
    # We always raise an exception if we find a missing parameter.
    def skip_missing_parameter?(key)
      raise RequestError, "missing required param '#{key}'"
    end        
  end
end