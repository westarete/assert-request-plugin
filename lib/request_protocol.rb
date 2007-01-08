require 'request_error'

module ValidateRequest
  # Defines how we handle and validate the request protocol.
  class RequestProtocol #:nodoc:
    
    def initialize(protocol)
      # Strip the trailing :// off the protocol.
      @protocol = protocol.sub(/:\/\/$/, '').to_sym
    end
    
    # Check the request protocol against the given set of permissible protocols.
    def validate(requirements)
      if requirements.empty?
        requirements = [:http]
      end
      unless requirements.detect {|m| @protocol == m}
        raise RequestError, "request protocol #{@protocol} is not permitted"
      end      
    end
    
  end 
end  
