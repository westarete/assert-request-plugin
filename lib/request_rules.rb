# assert_request Rails Plugin
#
# (c) Copyright 2007 by West Arete Computing, Inc.

module AssertRequest
  
  # This is the class that is supplied as an argument to the block in an
  # assert_request call. You use it to describe the request methods, 
  # parameters, and protocols that are permitted for this request. 
  class RequestRules 
    attr_reader :methods, :protocols #:nodoc:

    def initialize #:nodoc:
      @methods      = []
      @protocols    = []
      @params       = ParamRules.new
    end

    # Used to describe the request methods that are permitted for this 
    # request. Takes a list of permitted request methods as symbols for its
    # arguments. For example:
    # 
    #   assert_request do |r|
    #     r.method :put, :post
    #   end
    # 
    # This declaration says that the request method must be either PUT or
    # POST.
    # 
    # If you don't include this call in your assert_request declaration, then
    # assert_request will presume that only :get is allowed.
    #
    def method(*methods)
      @methods = @methods.concat(methods).flatten
    end

    # Used to describe the protocols that are permitted for this 
    # request. Takes a list of permitted protocols as symbols for its
    # arguments. For example:
    # 
    #   assert_request do |r|
    #     r.protocol :https
    #   end
    # 
    # This declaration says that the request protocol must be via HTTPS.
    # 
    # If you don't include this call in your assert_request declaration, then
    # assert_request will presume that only :http is allowed.
    #
    def protocol(*protocols)
      @protocols = @protocols.concat(protocols).flatten
    end
    
    # Used to describe the params hash for this request. Most commonly, the
    # must_have, may_have, and must_not_have methods are chained on to this
    # method to describe the params structure. For example:
    #
    #   assert_request do |r|
    #     r.params.must_have :id
    #   end
    #
    # For more details, see the methods that can be called on the result
    # of this method:
    # 
    # * ParamRules#must_have
    # * ParamRules#may_have
    # * ParamRules#is_a
    # * ParamRules#must_not_have
    #
    def params
      @params
    end

  end
end

