require 'abstract_params'

module ValidateRequest
  # A child of AbstractParams that doesn't mind of some of the permitted 
  # parameters are missing from the actual parameters.
  class OptionalParams < AbstractParams
    protected
    # We always skip a missing parameter.
    def skip_missing_parameter?(key)
      true
    end
  end
end