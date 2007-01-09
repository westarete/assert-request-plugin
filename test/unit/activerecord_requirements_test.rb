require File.dirname(__FILE__) + '/../test_helper'
require 'activerecord_requirements'

# Simple model to use while testing ActiveRecord requirement types.
class Dog < ActiveRecord::Base ; end

class ActiveRecordRulesTest < Test::Unit::TestCase

  include ValidateRequest
  
  # Preserve class variables, so that we can mess with them, and they'll be
  # restored for any other tests.
  def setup
    @old_ignore_columns = ActiveRecordRules.ignore_columns
  end
  
  def teardown
    ActiveRecordRules.ignore_columns = @old_ignore_columns
  end

  def test_ignore_columns
    old_value = ActiveRecordRules.ignore_columns
    assert_equal old_value, ActiveRecordRules.ignore_columns
    new_value = %( a b c )
    assert_not_equal old_value, new_value
    ActiveRecordRules.ignore_columns = new_value
    assert_equal new_value, ActiveRecordRules.ignore_columns
    ActiveRecordRules.ignore_columns << "d"
    new_value << "d"
    assert_equal new_value, ActiveRecordRules.ignore_columns
  end
    
  def test_no_models
    assert_equal({}, ActiveRecordRules.new({}).expand)
    assert_equal({:id => :integer}, ActiveRecordRules.new({:id => :integer}).expand)
    assert_equal({:id => :integer, :name => {:first => :string}}, ActiveRecordRules.new({:id => :integer, :name => {:first => :string}}).expand)
  end
  
  def test_model
    assert_equal({:dog=>{"name"=>:text, "breed"=>:text, "age_in_years"=>:integer}}, ActiveRecordRules.new({:dog => Dog}).expand)
    assert_equal({:pound => {:dog=>{"name"=>:text, "breed"=>:text, "age_in_years"=>:integer}}}, ActiveRecordRules.new({:pound => {:dog => Dog}}).expand)
    assert_equal({:dog1=>{"name"=>:text, "breed"=>:text, "age_in_years"=>:integer}, :dog2=>{"name"=>:text, "breed"=>:text, "age_in_years"=>:integer}}, ActiveRecordRules.new({:dog1 => Dog, :dog2 => Dog}).expand)
  end

  def test_model_with_except
    assert_equal({:dog=>{"name"=>:text, "age_in_years"=>:integer}}, ActiveRecordRules.new({:dog => Dog, :except => :breed}).expand)
    assert_equal({:dog=>{"breed"=>:text, "age_in_years"=>:integer}}, ActiveRecordRules.new({:dog => Dog, :except => :name}).expand)
  end 
  
  def test_model_with_multiple_excepts
    assert_equal({:dog=>{"age_in_years"=>:integer}}, ActiveRecordRules.new({:dog => Dog, :except => [:name, :breed]}).expand)
  end
  
  def test_different_models_with_different_excepts
    assert_equal({:dog=>{"breed"=>:text, "age_in_years"=>:integer}, :nested => {:dog=>{"name"=>:text, "age_in_years"=>:integer}}}, ActiveRecordRules.new({:dog => Dog, :except => :name, :nested => {:dog => Dog, :except => :breed}}).expand)    
  end
  
  def test_nested_model_with_except
    assert_equal({:pound => {:dog=>{"name"=>:text, "age_in_years"=>:integer}}}, ActiveRecordRules.new(:pound => {:dog => Dog, :except => :breed}).expand)
  end
  
  def test_except_without_model_should_be_treated_like_a_normal_argument
    assert_equal({:id => :integer, :except => :text}, ActiveRecordRules.new({:id => :integer, :except => :text}).expand)
    assert_equal({:id => :integer, :except => :text}, ActiveRecordRules.new({:id => :integer, :except => :text}).expand)
  end
  
end