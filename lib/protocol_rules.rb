require 'request_error'

module ValidateRequest
  # Defines how we handle and validate the request protocol.
  class ProtocolRules #:nodoc:
    attr_reader :requirements
    
    def initialize(requirements=[])
      @requirements = []
      @requirements << requirements
      @requirements.flatten!
      if @requirements.empty?
        @requirements << :http
      end
    end
    
    # Check the given request protocol.Raises an exception if it is invalid.
    def validate(protocol)
      # method.protocol leaves a trailing :// on its results.
      protocol = protocol.sub(/:\/\/$/, '').to_sym
      unless @requirements.include? protocol
        raise RequestError, "protocol #{protocol} is not permitted"
      end      
    end
    
  end 
end  
