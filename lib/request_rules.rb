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
      process_parameters(@requirements, requirements)
    end

    # Add one or more parameter definitions (e.g. :author => :string) to the
    # list of optional parameters.
    def optional(options)
      process_parameters(@options, options)
    end    
    
    private
    
    # Process the given requirements hash, and save the results in the 
    # variable given in "save".
    def process_parameters(save, params)
      params.each do |key, requirement|
        # If the requirement is an ActiveRecord class, expand it into a 
        # requirements hash of its content columns and their types. This 
        # effectively simulates the user having specified all of the model's
        # columns by hand using the standard hash notation.
        if ActiveRecordRequirement.is_model? requirement
          requirement = ActiveRecordRequirement.new(requirement).to_hash
        end
        
        save[key] = requirement
      end
    end
    
  end
end