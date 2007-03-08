module AssertRequest
  # Holds the definition of the rules for a valid request
  class RequestRules #:nodoc:
    attr_reader :methods, :protocols, :params

    def initialize
      @methods      = []
      @protocols    = []
      @params       = ParamRules.new
    end

    # Add one or more request methods (symbol name, e.g. :get) to the list of  
    # permitted methods. By default, only GET requests are permitted.
    def method(*methods)
      @methods = @methods.concat(methods).flatten
    end

    # Add one or more request protocols (symbol name, e.g. :https) to the list 
    # of permitted protocols. By default, only http is permitted.
    def protocol(*protocols)
      @protocols = @protocols.concat(protocols).flatten
    end

  end
end

