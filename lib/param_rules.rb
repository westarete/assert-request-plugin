require 'request_error'

module AssertRequest
  
  class ParamRules #:nodoc:
    attr_reader :name, :parent, :children
    cattr_accessor :ignore_params, :ignore_columns
    
    # The set of params that we should ignore by default. You could modify 
    # this in your environment.rb if its default settings don't suit your 
    # appliction. 
    @@ignore_params = %w( action controller commit _method )

    # The set of columns in the ActiveRecord model that we should ignore by
    # default. You could modify this in your environment.rb if its default 
    # settings don't suit your appliction. 
    @@ignore_columns = %w( id created_at updated_at created_on updated_on lock_version )
    
    # TODO: Convert this to a hash of options.
    def initialize(name=nil, parent=nil, required=true, ignore_unexpected=false)
      if (name.nil? && !parent.nil?) || (parent.nil? && !name.nil?)
        raise "parent and name must both be either nil or not nil"
      end
      # We store names as strings, since that's what the params hash uses.
      @name = name.nil? ? nil : name.to_s
      @parent = parent
      @required = required
      @children = []
      # Whether to raise an exception when we encounter unexpected params 
      # during validation.
      @ignore_unexpected = ignore_unexpected
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
    
    def must_not_have(*args)
      remove_child(*args)
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
      unless unexpected_keys.empty?
        raise RequestError, "did not expect #{canonical_name}[:#{unexpected_keys.first}]" unless @ignore_unexpected
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
    def add_child(required, *names)
      if block_given? && names.length != 1
        raise "you must supply exactly one parameter name with a block"
      end
      names.each do |name|
        child = ParamRules.new(name, self, required, @ignore_unexpected)
        yield child if block_given?
        @children << child
      end          
    end
   
    # Remove the given children. 
    def remove_child(*names)
      names.each do |name|
        children.delete_if { |child| child.name == name.to_s }
      end          
    end
   
    # Validate our children against the given params, looking for missing 
    # required elements. Returns a list of the keys that we were able to
    # recognize.
    def validate_children(params)
      recognized_keys = []
      children.each do |child|
        if params.has_key?(child.name)
          recognized_keys << child.name
          validate_child(child, params[child.name])
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