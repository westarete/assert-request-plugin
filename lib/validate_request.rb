# validate_request Rails Plugin
#
# (c) Copyright 2006 by West Arete Computing, Inc.

module ValidateRequest

  protected

  # The exception that we raise when we find an invalid request.
  class RequestError < RuntimeError ; end
  
  # Holds the definition of the rules for a valid request
  class RequestRules
    attr_reader :methods, :requirements, :options

    def initialize(methods=[], requirements={}, options={})
      @methods      = methods
      @requirements = requirements
      @options    = options
    end

    # Add one or more request methods (symbol name, e.g. :get) to the list of  
    # permitted methods. 
    def method(*methods)
      @methods = @methods.concat methods
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
  
  # Call this method at the beginning of your action to verify that the current
  # parameters match your idea of a valid set of values.
  def assert_valid_request(methods=:get, requirements={}, options={})
    if block_given?
      rules = RequestRules.new
      yield rules
    else
      rules = RequestRules.new(methods, requirements, options)
    end
    
    # Remove the common parameters that are provided on each call, and don't
    # need to be declared to validate_request.
    original_params = params.dup
    [:action, :controller, :commit].each {|key| original_params.delete(key)}
    
    # Validate the request method.
    RequestMethod.new(request.method).validate(rules.methods)
    
    # Verify and eliminate all of the required arguments
    required = RequiredParams.new(original_params)
    required.validate_and_delete!(rules.requirements)
    
    # Continue to verify and eliminate all of the optional arguments
    optional = OptionalParams.new(required.params)
    optional.validate_and_delete!(rules.options)
    
    # There shouldn't be anything left
    unexpected = optional.params
    unless unexpected.empty?
      raise RequestError, "unexpected parameters: #{unexpected.inspect}"
    end
    
    true
  rescue RequestError
    # Temporarily intercept the exception here so that we can log the details.
    logger.error "Bad request: #{$!}" 
    logger.debug "  Method:"
    logger.debug "    permitted: #{rules.methods.inspect}"
    logger.debug "    actual:    #{request.method.inspect}"
    logger.debug "  Parameters:"
    logger.debug "    required:  #{rules.requirements.inspect}"
    logger.debug "    optional:  #{rules.options.inspect}"
    logger.debug "    actual:    #{original_params.inspect}"
    raise
  end
  
  # TODO: Remove validate_request alias before v1.0
  # validate_request is deprecated, but included for now for backwards 
  # compatibility.
  alias_method :validate_request, :assert_valid_request
  
  private

  # Represents one key/value parameter pair
  class ParameterPair
    attr_accessor :key, :value
  
    def initialize(key, value)
      @key, @value = key, value
    end

    # Check this parameter's value against the given type.
    def validate(requirement)
      # No real checking necessary for text or string
      return if requirement == :text or requirement == :string
      if requirement == :integer
        unless @value.to_s =~ /^\d+$/
          raise RequestError, "bad value for #{@key}: #{@value} is not an integer"
        end
      else
        unless @value == requirement
          raise RequestError, "bad value for #{@key}: #{@value} != '#{requirement}'"
        end
      end        
    end
  end
  
  # Defines how we handle and validate the request method.
  class RequestMethod
    
    def initialize(method)
      @method = method
    end
    
    # Check the request method against the given set of permissible methods.
    def validate(requirements)
      # Make sure we're dealing with an array
      requirements = [requirements] unless requirements.respond_to? 'detect'
      unless requirements.detect {|m| @method == m}
        raise RequestError, "request method #{@method} is not permitted"
      end      
    end
    
  end # class RequestMethod
  
  # An abstract class that describes how we generally treat sets of parameters
  # and their requirements.
  class AbstractParams
    attr_reader :params
    
    def initialize(params)
      @params = params.dup
    end

    # Remove our params that match the given requirements
    def validate_and_delete!(requirements, parameters=@params)
      requirements.each do |key, requirement|
        # Convert keys from symbols to strings, since that's how they appear
        # in the params hash.
        key = key.to_s

        value = parameters[key]
        if value.nil?
          next if skip_missing_parameter?(key)
        end
        
        # If the requirement is an ActiveRecord class, expand it into a 
        # requirements hash of its content columns and their types.
        if is_model? requirement
          requirement = expand_active_record_to_hash_requirement(requirement)
        end
        
        if requirement.kind_of? Hash
          unless value.kind_of? Hash        
            raise RequestError, "parameter '#{key}' is not a compound value"
          end
          validate_and_delete!(requirement, value)
          parameters.delete(key) if value.empty?
        else
          ParameterPair.new(key, value).validate(requirement)
          parameters.delete(key)
        end
      end
    end
    
    protected

    # Child classes must implement this method, which determines how we 
    # behave in the face of a missing parameter compared to our requirements.
    def skip_missing_parameter?(key)
      raise "not implemented"
    end    

    private
    
    # Determine if the given requirement is an ActiveRecord model.
    def is_model?(requirement)
      requirement.respond_to? :ancestors and
        requirement.ancestors.detect {|a| a == ActiveRecord::Base}
    end
    
    # Pick out the desired content columns from the given activerecord class.
    def validate_columns(klass)
      ignore = %w( created_at updated_at created_on updated_on created_by updated_by )
      columns = []
      klass.content_columns.each do |column|
        columns << column unless ignore.detect {|name| name == column.name }
      end
      columns
    end

    # Expand the given ActiveRecord::Base class into a requirements hash of 
    # its content columns and their types.
    def expand_active_record_to_hash_requirement(klass)
      requirements = {}
      validate_columns(klass).each do |column|
        # For right now, we only support integer and text.
        requirements[column.name] = (column.type == :integer) ? :integer : :text
      end
      requirements
    end
    
  end # class AbstractParams
  
  # A child of AbstractParams that always requires that the parameters match
  # the requirements exactly.
  class RequiredParams < AbstractParams
    protected
    # We always raise an exception if we find a missing parameter.
    def skip_missing_parameter?(key)
      raise RequestError, "missing parameter '#{key}'"
    end        
  end
    
  # A child of AbstractParams that doesn't mind of some of the permitted 
  # parameters are missing from the actual parameters.
  class OptionalParams < AbstractParams
    protected
    # We always skip a missing parameter.
    def skip_missing_parameter?(key)
      true
    end
  end
    
end # module ValidateRequest
