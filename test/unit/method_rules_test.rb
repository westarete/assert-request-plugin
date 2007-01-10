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
    assert_equal [:get], MethodRules.new([]).requirements
  end
end