module ValidateRequest
  # Holds the definition of the rules for a valid request
  class RequestRules
    attr_reader :methods, :requirements, :options

    def initialize(methods=[], requirements={}, options={})
      @methods      = []
      @requirements = {}
      @options      = {}
      method(methods)
      required(requirements)
      optional(options)
    end

    # Add one or more request methods (symbol name, e.g. :get) to the list of  
    # permitted methods. 
    def method(*methods)
      @methods = @methods.concat(methods).flatten
    end

    # Add one or more parameter definitions (e.g. :id => :integer) to the
    # list of required parameters.
    def required(requirements)
      @requirements.merge! requirements
    end

    # Add one or more parameter definitions (e.g. :author => :string) to the
    # list of optional parameters.
    def optional(options)
      @options.merge! options
    end    
  end
end