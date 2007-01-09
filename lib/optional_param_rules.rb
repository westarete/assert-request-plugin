require 'param_rules'

module ValidateRequest
  # A child of ParamRules that doesn't mind of some of the permitted 
  # parameters are missing from the actual parameters.
  class OptionalParamRules < ParamRules #:nodoc:
    protected
    # We always skip a missing parameter.
    def skip_missing_parameter?(key)
      true
    end
  end
end