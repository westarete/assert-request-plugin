require 'activerecord_rules'

class Hash #:nodoc:
  # Merge the given hash with the current hash, doing the same with any nested 
  # hashes. 
  def nested_merge!(another_hash)
    another_hash.each do |key, value|
      if self.has_key? key and self[key].is_a? Hash and value.is_a? Hash 
        # Merge the two values
        self[key].nested_merge! value
      else
        # Regular merge
        self[key] = value
      end
    end
  end
end

module ValidateRequest
  # Holds the definition of the rules for a valid request
  class RequestRules #:nodoc:
    attr_reader :methods, :requirements, :options, :protocols

    def initialize(methods=[], requirements={}, options={}, protocols=[])
      @methods      = []
      @requirements = {}
      @options      = {}
      @protocols    = []
      method(methods)
      required(requirements)
      optional(options)
      protocol(protocols)
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

    # Add one or more parameter definitions (e.g. :id => :integer) to the
    # list of required parameters.
    def required(requirements)
      @requirements.nested_merge! ActiveRecordRules.new(requirements).expand
    end

    # Add one or more parameter definitions (e.g. :author => :string) to the
    # list of optional parameters.
    def optional(options)
      @options.nested_merge! ActiveRecordRules.new(options).expand
    end
    
  end
end

