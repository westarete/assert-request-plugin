require 'params'

module ValidateRequest
  # A child of Params that always requires that the parameters match
  # the requirements exactly.
  class RequiredParams < Params #:nodoc:
    protected
    # We always raise an exception if we find a missing parameter.
    def skip_missing_parameter?(key)
      raise RequestError, "missing parameter '#{key}'"
    end        
  end
end