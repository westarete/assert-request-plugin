require 'request_error'

module AssertRequest
  
  class ParamRules #:nodoc:
    attr_reader :name, :parent, :children
    
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

    def canonical_name
      if parent.nil?
        "params"
      else
        parent.canonical_name + "[:#{name}]" 
      end
    end
    

    private
    
    # Create a new child. The first argument is boolean and says whether the
    # child is required (must_have) or not (may_have).
    def add_child(required, *args)
      if block_given? and args.length != 1
        raise "you must supply a parameter with a block"
      end
      args.each do |arg|
        child = ParamRules.new(arg, self, required)
        yield child if block_given?
        @children << child
      end          
    end
    
  end
  
end