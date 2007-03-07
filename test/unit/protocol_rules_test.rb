require File.dirname(__FILE__) + '/../test_helper'
require 'method_rules'

class ProtocolRulesTest < Test::Unit::TestCase
  include AssertRequest

  def test_initialize
    assert_equal [:http], ProtocolRules.new(:http).requirements
    assert_equal [:http], ProtocolRules.new([:http]).requirements
    assert_equal [:http, :https], ProtocolRules.new([:http, :https]).requirements
  end

  def test_requirements_default_to_http
    assert_equal [:http], ProtocolRules.new.requirements
    assert_equal [:http], ProtocolRules.new([]).requirements
  end
  
  def test_validate
    rules = ProtocolRules.new
    assert_not_raise(RequestError) { rules.validate('http://') }
    assert_raise(RequestError) { rules.validate('https://') }
    
    rules = ProtocolRules.new :https
    assert_not_raise(RequestError) { rules.validate('https://') }
    assert_raise(RequestError) { rules.validate('http://') }
    
    rules = ProtocolRules.new [:http, :https]
    assert_not_raise(RequestError) { rules.validate('http://') }
    assert_not_raise(RequestError) { rules.validate('https://') }
    assert_raise(RequestError) { rules.validate('ftp://') }
  end
  
end