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
  
  def test_requirements
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
  
  def test_options
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
