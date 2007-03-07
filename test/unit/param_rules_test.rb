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
  
  def test_nested
    parent = ParamRules.new
    child1 = add_child(parent, true, :id)
    child2 = add_child(parent, false, :name)
    grandchild1 = add_child(child1, false, :person)
    grandchild2 = add_child(child1, false, :person)
    assert_equal 2, parent.children.length
    assert_equal 2, child1.children.length
    assert_equal 0, child2.children.length
    assert_equal 0, grandchild1.children.length
    assert_equal 0, grandchild2.children.length
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