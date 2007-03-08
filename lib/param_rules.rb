require 'request_error'

module AssertRequest
  
  class ParamRules #:nodoc:
    attr_reader :name, :parent, :children
    cattr_accessor :ignore_params, :ignore_columns
    
    # The set of params that we should ignore by default. You could modify 
    # this in your environment.rb if its default settings don't suit your 
    # appliction. 
    @@ignore_params = %w( action controller commit method )

    # The set of columns in the ActiveRecord model that we should ignore by
    # default. You could modify this in your environment.rb if its default 
    # settings don't suit your appliction. 
    @@ignore_columns = %w( id created_at updated_at created_on updated_on lock_version )
    
    def initialize(name=nil, parent=nil, required=true)
      if (name.nil? && !parent.nil?) || (parent.nil? && !name.nil?)
        raise "parent and name must both be either nil or not nil"
      end
      @name = name
      @parent = parent
      @required = required
      @children = []
    end
    
    def required?
      @required
    end
    
    def must_have(*args, &block)
      add_child(true, *args, &block)
    end
    
    def may_have(*args, &block)
      add_child(false, *args, &block)
    end
    
    def is_a(klass)
      unless is_model?(klass)
        raise "you must supply an ActiveRecord class to the is_a method"
      end
      klass.columns.each do |c|
        must_have c.name unless ignore_column?(c)
      end
    end

    def canonical_name
      if parent.nil?
        "params"
      else
        parent.canonical_name + "[:#{name}]" 
      end
    end
    
    # Validate the given parameters against our requirements, raising 
    # exceptions for missing or unexpected parameters.
    def validate(params)
      recognized_keys = validate_children(params)
      unexpected_keys = params.keys - recognized_keys
      if parent.nil?
        # Only ignore the standard params at the top level.
        unexpected_keys -= @@ignore_params
      end
      if !unexpected_keys.empty?
        raise RequestError, "did not expect #{canonical_name}[:#{unexpected_keys.first}]"
      end
    end

    private
    
    def ignore_column?(column)
      @@ignore_columns.detect { |name| name == column.name }
    end
    
    # Determine if the given class is an ActiveRecord model.
    def is_model?(klass)
      klass.respond_to?(:ancestors) &&
        klass.ancestors.detect {|a| a == ActiveRecord::Base}
    end
    
    # Create a new child. The first argument is boolean and says whether the
    # child is required (must_have) or not (may_have).
    def add_child(required, *args)
      if block_given? && args.length != 1
        raise "you must supply exactly one parameter name with a block"
      end
      args.each do |arg|
        child = ParamRules.new(arg, self, required)
        yield child if block_given?
        @children << child
      end          
    end
   
    # Validate our children against the given params, looking for missing 
    # required elements. Returns a list of the keys that we were able to
    # recognize.
    def validate_children(params)
      recognized_keys = []
      children.each do |child|
        name = child.name.to_s
        if params.has_key?(name)
          recognized_keys << name
          validate_child(child, params[name])
        elsif child.required?
          raise RequestError, "request did not include #{child.canonical_name}"
        end
      end
      recognized_keys
    end
    
    # Validate this child against its matching value. 
    def validate_child(child, value)
      if child.children.empty?
        if value.is_a?(Hash)
          raise RequestError, (child.canonical_name + " is a hash, but wasn't expecting it")
        end
      else
        if value.is_a?(Hash)
          child.validate(value)
        else
          raise RequestError, "expected #{child.canonical_name} to be a nested hash"
        end
      end      
    end
    
  end
  
end