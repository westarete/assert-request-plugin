require 'request_error'

module AssertRequest
  
  class ParamRules #:nodoc:
    attr_writer :required
    attr_accessor :name, :parent, :children
    
    def initialize(name=nil)
      @name = name
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

    private
    
    # Create a new child. The first argument is boolean and says whether the
    # child is required (must_have) or not (may_have).
    def add_child(required, *args)
      if block_given? and args.length != 1
        raise "you must supply a parameter with a block"
      end
      args.each do |arg|
        child = ParamRules.new(arg)
        child.required = required
        child.parent = self
        yield child if block_given?
        @children << child
      end          
    end
    
  end
  
end