require File.dirname(__FILE__) + '/../test_helper'
require 'request_rules'

class RequestRulesTest < Test::Unit::TestCase

  include AssertRequest
    
  def test_methods
    r = RequestRules.new
    assert_equal [], r.methods
    r.method :get
    assert_equal [:get], r.methods
    r.method :post
    assert_equal [:get, :post], r.methods
    r.method :put, :delete
    assert_equal [:get, :post, :put, :delete], r.methods
  end

  def test_protocols
    r = RequestRules.new
    assert_equal [], r.protocols
    r.protocol :http
    assert_equal [:http], r.protocols
    r.protocol :https
    assert_equal [:http, :https], r.protocols
  end
  
  def test_params
    r = RequestRules.new
    assert r.params.children.empty?
    assert r.params.parent.nil?
    assert r.params.name.nil?
  end

end
