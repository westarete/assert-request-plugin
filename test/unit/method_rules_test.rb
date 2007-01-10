require File.dirname(__FILE__) + '/../test_helper'
require 'method_rules'

class MethodRulesTest < Test::Unit::TestCase
  include ValidateRequest

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
  
  private
  
  # The opposite of assert_raise
  def assert_not_raise(exception, &block)
    yield
    assert true
  rescue exception => e
    flunk "Received a #{exception.to_s} exception, but wasn't expecting one: #{e}"
  end
  
end