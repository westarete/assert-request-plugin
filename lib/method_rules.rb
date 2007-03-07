require 'request_error'

module AssertRequest
  # Defines how we handle and validate the request method.
  class MethodRules #:nodoc:
    attr_reader :requirements
    
    def initialize(requirements=[])
      @requirements = []
      @requirements << requirements
      @requirements.flatten!
      if @requirements.empty?
        @requirements << :get
      end
    end
    
    # Check the given request method. Raises an exception if it is invalid.
    def validate(method)
      unless @requirements.include? method
        raise RequestError, "request method #{method} is not permitted"
      end      
    end
    
  end 
end  
