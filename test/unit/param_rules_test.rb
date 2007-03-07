require File.dirname(__FILE__) + '/../test_helper'

class ParamRulesTest < Test::Unit::TestCase

  include AssertRequest
  
  def test_empty
    params = ParamRules.new
    assert_nil params.name
    assert_nil params.parent
    assert params.children.empty?
  end
  
  def test_parent_and_name_must_both_be_nil_or_non_nil
    parent = ParamRules.new
    assert_raise(RuntimeError) { ParamRules.new(nil, parent) }
    assert_raise(RuntimeError) { ParamRules.new("hi", nil)   }
    ParamRules.new("hi", parent)
  end
  
  def test_with_simple_must_have
    add_child(ParamRules.new, true, :id)
  end
  
  def test_simple_may_have
    add_child(ParamRules.new, false, :id)
  end
  
  def test_list_of_names
    params = ParamRules.new
    params.must_have :id, :name, :email
    assert_equal 3, params.children.length
    params.children.each do |child|
      assert_equal params, child.parent
      assert child.children.empty?
    end
    [:id, :name, :email].each do |name|
      assert params.children.detect { |c| c.name == name }
    end
  end
  
  def test_block_is_not_compatible_with_multiple_names
    assert_raise(RuntimeError) do
      ParamRules.new.must_have :id, :name do |p|
        p.must_have :email
      end
    end
  end
  
  def test_blocks
    root = ParamRules.new
    root.must_have :id
    root.must_have :person do |person|
      person.must_have :name
      person.may_have :age, :height
      person.may_have(:dog) { |d| d.must_have :id }
    end
    assert_equal 2, root.children.length
    assert_equal :id,     root.children.first.name
    person = root.children.last
    assert_equal :person, person.name
    assert_equal 4, person.children.length
    assert_equal :name, person.children[0].name
    assert_equal :age, person.children[1].name
    assert_equal :height, person.children[2].name
    assert_equal :dog, person.children[3].name
    dog = person.children[3]
    assert_equal 1, dog.children.length
    assert_equal :id, dog.children.first.name
  end
  
  def test_canonical_name
    root = ParamRules.new
    child1 = add_child(root, true, :id)
    child2 = add_child(root, false, :name)
    grandchild1 = add_child(child1, false, :person)
    grandchild2 = add_child(child1, false, :dog)
    assert_equal "params",               root.canonical_name
    assert_equal "params[:id]",          child1.canonical_name
    assert_equal "params[:name]",        child2.canonical_name
    assert_equal "params[:id][:person]", grandchild1.canonical_name
    assert_equal "params[:id][:dog]",    grandchild2.canonical_name
  end
  
  def test_validate_one_required_param
    root = ParamRules.new
    root.must_have :id
    assert_not_raise(AssertRequest::RequestError) { root.validate({"id" => 4}) }
    assert_raise(AssertRequest::RequestError) { root.validate({"not_id" => 4}) }
  end
  
  def test_validate_one_optional_param
    root = ParamRules.new
    root.may_have :id
    assert_not_raise(AssertRequest::RequestError) { root.validate({"id" => 4}) }
    assert_not_raise(AssertRequest::RequestError) { root.validate({"not_id" => 4}) }
  end

  def test_validate_multiple_params
    root = ParamRules.new
    root.must_have :id, :name
    assert_not_raise(AssertRequest::RequestError) { root.validate({"id" => 4, "name" => "john"}) }
    assert_raise(AssertRequest::RequestError) { root.validate({"id" => 4}) }
    assert_raise(AssertRequest::RequestError) { root.validate({"name" => "john"}) }
    assert_raise(AssertRequest::RequestError) { root.validate({}) }
  end
  
  def test_validate_nested_params
    root = ParamRules.new
    root.must_have :id
    root.must_have :person do |person|
      person.must_have :name do |name|
        name.must_have :first
      end
      person.must_have :age
    end
    assert_not_raise(AssertRequest::RequestError) { root.validate({"id" => 4, "person" => {"name" => {"first" => "john"}, "age" => 12}}) }
    assert_raise(AssertRequest::RequestError)     { root.validate({"id" => 4, "person" => {"name" => {"not_first" => "john"}, "age" => 12}}) }
    assert_raise(AssertRequest::RequestError)     { root.validate({"id" => 4, "person" => {"name" => {"first" => "john"}, "not_age" => 12}}) }
    assert_raise(AssertRequest::RequestError)     { root.validate({"id" => 4, "person" => {"name" => {"first" => "john"}}}) }
    assert_raise(AssertRequest::RequestError)     { root.validate({"id" => 4, "person" => {"not_name" => {"first" => "john"}, "age" => 12}}) }
  end    
  
  private
  
  # Add a new child with the given name and required status to the given
  # parent.
  def add_child(parent, required, name)
    old_num_children = parent.children.length
    if required
      parent.must_have name
    else
      parent.may_have name
    end
    assert_equal old_num_children+1, parent.children.length
    # Here we presume that the child got added to the end of the children.
    child = parent.children.last
    assert_equal name, child.name
    assert_equal parent, child.parent
    assert child.children.empty?
    if required
      assert child.required?    
    else
      assert ! child.required?
    end
    child
  end
end