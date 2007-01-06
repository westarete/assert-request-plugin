require 'test/unit'
require File.dirname(__FILE__) + '/../lib/activerecord_requirements'

class ActiveRecordRequirementsTest < Test::Unit::TestCase

  include ValidateRequest
  
  def setup
    @old_ignore_columns = ActiveRecordRequirements.ignore_columns
  end
  
  def teardown
    ActiveRecordRequirements.ignore_columns = @old_ignore_columns
  end

  def test_ignore_columns
    old_value = ActiveRecordRequirements.ignore_columns
    assert_equal old_value, ActiveRecordRequirements.ignore_columns
    new_value = %( a b c )
    assert_not_equal old_value, new_value
    ActiveRecordRequirements.ignore_columns = new_value
    assert_equal new_value, ActiveRecordRequirements.ignore_columns
    ActiveRecordRequirements.ignore_columns << "d"
    new_value << "d"
    assert_equal new_value, ActiveRecordRequirements.ignore_columns
  end


end