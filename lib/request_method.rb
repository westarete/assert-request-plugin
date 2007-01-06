require 'request_error'

module ValidateRequest
  # Defines how we handle and validate the request method.
  class RequestMethod
    
    def initialize(method)
      @method = method
    end
    
    # Check the request method against the given set of permissible methods.
    def validate(requirements)
      # Make sure we're dealing with an array.
      # TODO: This line can be removed after we only allow block declarations (v1.0).
      requirements = [requirements] unless requirements.respond_to? 'detect'
      if requirements.empty?
        requirements = [:get]
      end
      unless requirements.detect {|m| @method == m}
        raise RequestError, "request method #{@method} is not permitted"
      end      
    end
  end 
end  
