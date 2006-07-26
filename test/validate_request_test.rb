require File.dirname(__FILE__) + '/test_helper' 
require File.dirname(__FILE__) + '/../lib/validate_request'
require File.dirname(__FILE__) + '/validate_request_test_helper'

# Re-raise errors caught by the controller.
class ValidateRequestController; def rescue_action(e) raise e end; end

class ValidateRequestControllerTest < Test::Unit::TestCase
  def setup
    @controller = ValidateRequestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_none
    assert_valid_request :get, :none
    assert_invalid_request :get, :none, {:id => '3'}
  end

  def test_one_integer
    assert_valid_request :get, :one_integer, {:id => '3'}
    assert_invalid_request :get, :one_integer, {:id => '3a'}
    assert_invalid_request :get, :one_integer, {:count => '3'}
    assert_invalid_request :get, :one_integer
    assert_invalid_request :get, :one_integer, {:id => '3', :extra => '3'}
  end

  def test_multiple_integer_params
    assert_valid_request :get, :two_integers, {:id => '3', :count => '4'}
    assert_invalid_request :get, :two_integers, {:id => '3', :count => '4a'}
    assert_invalid_request :get, :two_integers, {:count => '4'}
    assert_invalid_request :get, :two_integers
    assert_invalid_request :get, :two_integers, {:id => '3', :count => '4', :extra => '5'}
  end

  def test_specific_params
    assert_valid_request :get, :one_specific, {:orientation => 'horizontal'}
    assert_invalid_request :get, :one_specific, {:orientation => 'vertical'}
    assert_invalid_request :get, :one_specific, {:orientation => 'horizontal', :extra => '5'}
    assert_invalid_request :get, :one_specific
  end

  def test_one_integer_one_specific
    assert_valid_request :get, :one_integer_one_specific, {:id => '4', :orientation => 'horizontal'}
    assert_invalid_request :get, :one_integer_one_specific, {:id => '4a', :orientation => 'horizontal'}
    assert_invalid_request :get, :one_integer_one_specific, {:id => '4'}
    assert_invalid_request :get, :one_integer_one_specific, {:orientation => 'horizontal'}
    assert_invalid_request :get, :one_integer_one_specific
    assert_invalid_request :get, :one_integer_one_specific, {:id => '4a', :orientation => 'horizontal', :extra => 'hi'}
    assert_invalid_request :get, :one_integer_one_specific, {:id => '4a', :orientation => 'vertical'}
  end
  
  def test_request_methods
    assert_valid_request :get, :get_only
    assert_invalid_request :post, :get_only
    assert_invalid_request :put, :get_only
    assert_invalid_request :delete, :get_only
    
    assert_valid_request :post, :post_only
    assert_invalid_request :get, :post_only
    assert_invalid_request :put, :post_only
    assert_invalid_request :delete, :post_only
    
    assert_valid_request :put, :put_only
    assert_invalid_request :post, :put_only
    assert_invalid_request :get, :put_only
    assert_invalid_request :delete, :put_only
    
    assert_valid_request :get, :get_or_post
    assert_valid_request :post, :get_or_post
    assert_invalid_request :put, :get_or_post
    assert_invalid_request :delete, :get_or_post
  end
  
  def test_optional
    action = :one_required_integer_one_optional_integer
    assert_valid_request :get, action, {:id => '4', :per_page => '10'}
    assert_valid_request :get, action, {:id => '4'}
    assert_invalid_request :get, action, {:per_page => '4'}
    assert_invalid_request :get, action, {:id => '4', :per_page => '10', :extra => '5'}
    assert_invalid_request :get, action, {:id => '4', :per_page => '10a'}
    assert_invalid_request :post, action, {:id => '4', :per_page => '10'}
  end
  
  def test_simple_nested_requirements
    assert_valid_request :get, :simple_nested, :id => '5', :page => {:count => '10'}
    assert_invalid_request :get, :simple_nested, :id => '5', :page => {:count => '10a'}
    assert_invalid_request :get, :simple_nested, :id => '5a', :page => {:count => '10'}
    assert_invalid_request :get, :simple_nested, :id => '5', :page => {:wrong => '10'}
    assert_invalid_request :get, :simple_nested, :id => '5', :wrong => {:count => '10'}
    assert_invalid_request :get, :simple_nested, :wrong => '5', :page => {:count => '10'}
    assert_invalid_request :get, :simple_nested, :id => '5', :page => {:count => '10', :extra => '5'}
    assert_invalid_request :get, :simple_nested, :id => '5', :page => {}
    assert_invalid_request :get, :simple_nested, :id => '5', :page => '10'
    assert_invalid_request :get, :simple_nested, :page => {:count => '10'}
    assert_invalid_request :get, :simple_nested
  end
  
  def test_double_nested_requirements
    assert_valid_request :get, :double_nested, :id => '5', :page => {:author => {:name => 'Jack Black'}}
    assert_invalid_request :get, :double_nested, :id => '5', :page => {:author => 'Jack'}
    assert_invalid_request :get, :double_nested, :id => '5', :page => {:author => {:name => 'Jack Black', :extra => '5'}}
    assert_invalid_request :get, :double_nested, :id => '5', :page => {:author => {:name => 'Jack Black'}, :extra => '5'}    
  end

  def test_nested_options
    action = :double_nested_with_options
    assert_valid_request :get, action, 
      :id => '5', 
      :page => {
        :author => {
          :name => 'Jack Black'
        }
      }
    assert_valid_request :get, action, 
      :id => '5', 
      :page => {
        :author => {
          :name => 'Jack Black', 
          :optional_email => 'jack@example.com'
        }
      }
    assert_valid_request :get, action, 
      :id => '5', 
      :page => {
        :author => {
          :name => 'Jack Black', 
          :optional_email => 'jack@example.com'
        },
        :optional_orientation => 'horizontal'
      }
    assert_valid_request :get, action, 
      :id => '5', 
      :page => {
        :author => {
          :name => 'Jack Black', 
          :optional_email => 'jack@example.com'
        },
        :optional_orientation => 'horizontal',
        :optional_coauthor => {
          :optional_name => 'Jack Johnson', 
          :optional_email => 'jj@example.com'
        },
      }
    assert_valid_request :get, action, 
      :id => '5', 
      :page => {
        :author => {
          :name => 'Jack Black', 
          :optional_email => 'jack@example.com'
        },
        :optional_orientation => 'horizontal',
        :optional_coauthor => {
          :optional_name => 'Jack Johnson', 
        },
      }
    assert_invalid_request :get, action, 
      :id => '5', 
      :page => {
        :author => {
          :name => 'Jack Black', 
          :optional_email => 'jack@example.com'
        },
        :optional_orientation => 'horizontal',
        :optional_coauthor => {
          :optional_name => 'Jack Johnson', 
          :not_allowed => 'bad'
        },
      }
    
  end
  
private

  # Works like "get" or "post", only it also asserts that we get a successful
  # response from validate_request.
  def assert_valid_request(method, *args)
    self.send(method.to_s, *args)
    assert_response :success
  end
  
  # Works like "get" or "post", only it also asserts that we get a failure
  # response from validate_request.
  def assert_invalid_request(method, *args)
    self.send(method.to_s, *args)
    assert_response :redirect
    assert_redirected_to '/error'    
  end
  
end
