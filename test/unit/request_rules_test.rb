require File.dirname(__FILE__) + '/../test_helper'
require 'request_rules'

class RequestRulesTest < Test::Unit::TestCase

  include ValidateRequest
  
  def test_methods_via_new
    assert_equal [], RequestRules.new.methods
    assert_equal [:get], RequestRules.new(:get).methods
    assert_equal [:get, :post], RequestRules.new([:get, :post]).methods
  end
  
  def test_additive_methods
    r = RequestRules.new
    assert_equal [], r.methods
    r.method :get
    assert_equal [:get], r.methods
    r.method :post
    assert_equal [:get, :post], r.methods
    r.method :put, :delete
    assert_equal [:get, :post, :put, :delete], r.methods
  end
  
  def test_requirements_via_new
    assert_equal({}, RequestRules.new.requirements)
    assert_equal({"id" => :integer}, RequestRules.new(:get, "id" => :integer).requirements)
    assert_equal({"id" => :integer, "name" => :string}, RequestRules.new(:get, "id" => :integer, "name" => :string).requirements)
    assert_equal({"id" => :integer, "name" => {"first" => :string}}, RequestRules.new(:get, "id" => :integer, "name" => { "first" => :string }).requirements)
  end
  
  def test_additive_requirements
    r = RequestRules.new
    assert_equal({}, r.requirements)
    r.required "id" => :integer
    assert_equal({"id" => :integer}, r.requirements)
    r.required "color" => :string
    assert_equal({"id" => :integer, "color" => :string}, r.requirements)
    r.required "x" => :integer, "y" => :integer
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer}, r.requirements)
    r.required "name" => {"first" => :string}
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer, "name" => {"first" => :string}}, r.requirements)
    r.required "name" => {"last" => :string}
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer, "name" => {"first" => :string, "last" => :string}}, r.requirements)
    r.required "name" => {"last" => {"letter" => :string, "number" => :integer}}
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer, "name" => {"first" => :string, "last" => {"letter" => :string, "number" => :integer}}}, r.requirements)
    r.required "name" => {"last" => {"deep" => {"letter" => :string, "number" => :integer}}}
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer, "name" => {"first" => :string, "last" => {"letter" => :string, "number" => :integer, "deep" => {"letter" => :string, "number" => :integer}}}}, r.requirements)
  end
  
  def test_options_via_new
    assert_equal({}, RequestRules.new.options)
    assert_equal({"id" => :integer}, RequestRules.new(:get, {}, "id" => :integer).options)
    assert_equal({"id" => :integer, "name" => :string}, RequestRules.new(:get, {}, "id" => :integer, "name" => :string).options)
    assert_equal({"id" => :integer, "name" => {"first" => :string}}, RequestRules.new(:get, {}, "id" => :integer, "name" => { "first" => :string }).options)
  end
  
  def test_additive_options
    r = RequestRules.new
    assert_equal({}, r.options)
    r.optional "id" => :integer
    assert_equal({"id" => :integer}, r.options)
    r.optional "color" => :string
    assert_equal({"id" => :integer, "color" => :string}, r.options)
    r.optional "x" => :integer, "y" => :integer
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer}, r.options)
    r.optional "name" => {"first" => :string}
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer, "name" => {"first" => :string}}, r.options)
    r.optional "name" => {"last" => :string}
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer, "name" => {"first" => :string, "last" => :string}}, r.options)
    r.optional "name" => {"last" => {"letter" => :string, "number" => :integer}}
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer, "name" => {"first" => :string, "last" => {"letter" => :string, "number" => :integer}}}, r.options)
    r.optional "name" => {"last" => {"deep" => {"letter" => :string, "number" => :integer}}}
    assert_equal({"id" => :integer, "color" => :string, "x" => :integer, "y" => :integer, "name" => {"first" => :string, "last" => {"letter" => :string, "number" => :integer, "deep" => {"letter" => :string, "number" => :integer}}}}, r.options)
  end
  
end
