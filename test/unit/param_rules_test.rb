require File.dirname(__FILE__) + '/../test_helper'
require 'required_param_rules'
require 'optional_param_rules'

class ParamRulesTest < Test::Unit::TestCase

  include ValidateRequest
  
  # Preserve class variables, so that we can mess with them, and they'll be
  # restored for any other tests.
  def setup
    @old_ignore_params = ParamRules.ignore_params.dup
  end
  
  def teardown
    ParamRules.ignore_params = @old_ignore_params
  end

  def test_single_variable
    rules = RequiredParamRules.new 'id' => :integer
    assert_equal({}, rules.validate('id' => '5'))
    assert_equal({'extra' => 'unknown'}, rules.validate('id' => '5', 'extra' => 'unknown'))
    assert_raise(ValidateRequest::RequestError) { rules.validate({'id' => 'not_an_integer'}) }
  end
  
  def test_multiple_variables
    rules = RequiredParamRules.new 'id' => :integer, 'name' => :string
    assert_equal({}, rules.validate('id' => '5', 'name' => 'Tony'))
    assert_equal({'extra' => 'unknown'}, rules.validate('id' => '5', 'name' => 'Tony', 'extra' => 'unknown'))
  end
  
  def test_collection
    requirements = {'person' => {[] => {'name' => :string}}}
    required = RequiredParamRules.new requirements
    optional = OptionalParamRules.new requirements
    assert_equal({}, required.validate('person' => {'1' => {'name' => 'Tony'}}))    
    assert_equal({}, required.validate('person' => {'1' => {'name' => 'Tony'}, '2' => {'name' => 'Bob'}}))    
    
    assert_equal({'person' => {'1' => {'extra' => 'unknown'}}}, required.validate('person' => {'1' => {'name' => 'Tony', 'extra' => 'unknown'}}))
    assert_raise(ValidateRequest::RequestError) { required.validate('not_a_person' => {'1' => {'name' => 'Tony'}, '2' => {'name' => 'Bob'}}) }
    assert_raise(ValidateRequest::RequestError) { required.validate('person' => {'not_an_index' => {'name' => 'Tony'}}) }
    assert_raise(ValidateRequest::RequestError) { required.validate('person' => {'1' => {'not_a_name' => 'Tony'}}) }
    assert_raise(ValidateRequest::RequestError) { required.validate('person' => {'1' => {}}) }
    assert_raise(ValidateRequest::RequestError) { required.validate('person' => {}) }
    
    assert_equal({}, optional.validate('person' => {'1' => {'name' => 'Tony'}}))    
    assert_equal({}, optional.validate('person' => {'1' => {'name' => 'Tony'}, '2' => {'name' => 'Bob'}}))
    assert_equal({}, optional.validate({}))
    assert_raise(ValidateRequest::RequestError) { assert_equal({}, required.validate({})) }
  end

  def test_bad_collection_declaration
    requirements = {'person' => {['key_should_be_an_empty_array'] => {'name' => :string}}}
    params       = {'person' => {['key_should_be_an_empty_array'] => {'name' => 'Tony'}}}
    assert_raise(RuntimeError) { RequiredParamRules.new(requirements).validate(params) }
  end

  def test_standard_ignore_params
    rules = RequiredParamRules.new 'id' => :integer    
    assert_equal({}, rules.validate('id' => '5', 'action' => 'show', 'controller' => 'person', 'commit' => 'Save', 'method' => 'put'))
  end
  
  def test_custom_ignore_params
    rules  = RequiredParamRules.new 'id' => :integer    
    params = {'id' => '5', 'extra' => 'unknown', 'action' => 'show'}
    assert_equal({'extra' => 'unknown'}, rules.validate(params))
    ParamRules.ignore_params << 'extra'
    assert_equal({}, rules.validate(params))
  end

end