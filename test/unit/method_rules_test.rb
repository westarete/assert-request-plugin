require File.dirname(__FILE__) + '/../test_helper'
require 'method_rules'

class MethodRulesTest < Test::Unit::TestCase
  include AssertRequest

  def test_initialize
    assert_equal [:get], MethodRules.new(:get).requirements
    assert_equal [:get], MethodRules.new([:get]).requirements
    assert_equal [:get, :post], MethodRules.new([:get, :post]).requirements
  end

  def test_requirements_default_to_get
    assert_equal [:get], MethodRules.new.requirements
    assert_equal [:get], MethodRules.new([]).requirements
  end
  
  def test_validate
    rules = MethodRules.new
    assert_not_raise(RequestError) { rules.validate(:get) }
    assert_raise(RequestError) { rules.validate(:post) }
    
    rules = MethodRules.new :post
    assert_not_raise(RequestError) { rules.validate(:post) }
    assert_raise(RequestError) { rules.validate(:get) }
    
    rules = MethodRules.new [:get, :post]
    assert_not_raise(RequestError) { rules.validate(:get) }
    assert_not_raise(RequestError) { rules.validate(:post) }
    assert_raise(RequestError) { rules.validate(:put) }
  end
  
end