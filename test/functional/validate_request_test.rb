# validate_request Rails Plugin
#
# (c) Copyright 2006 by West Arete Computing, Inc.

require File.dirname(__FILE__) + '/../test_helper'
require 'validate_request'
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

  def test_method_ruless
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

  def test_required_model
    assert_valid_request :get, :required_dog, :id => '5', :dog => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12'}
    assert_invalid_request :get, :required_dog, :id => '5', :dog => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12a'}
    assert_invalid_request :get, :required_dog, :id => '5a', :dog => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12'}
    assert_invalid_request :get, :required_dog, :id => '5', :dog => {:breed => 'bouvier', :age_in_years => '12'}
    assert_invalid_request :get, :required_dog, :id => '5', :dog => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12', :extra => 'bad'}
    assert_invalid_request :get, :required_dog, :id => '5', :dog => {}
    assert_invalid_request :get, :required_dog, :id => '5', :dog => ''
    assert_invalid_request :get, :required_dog, :id => '5', :dog => nil
  end
  
  def test_optional_model
    assert_valid_request :get, :optional_dog, :id => '5', :dog => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12'}
    assert_valid_request :get, :optional_dog, :id => '5', :dog => {:breed => 'bouvier', :age_in_years => '12'}
    assert_valid_request :get, :optional_dog, :id => '5', :dog => {}
    assert_valid_request :get, :optional_dog, :id => '5'
    assert_invalid_request :get, :optional_dog, :id => '5', :dog => ''
    assert_invalid_request :get, :optional_dog, :id => '5', :dog => nil
    assert_invalid_request :get, :optional_dog, :id => '5', :dog => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12a'}
    assert_invalid_request :get, :optional_dog, :id => '5', :dog => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12', :extra => 'bad'}    
  end
  
  def test_protocol
    assert_invalid_request :get, :must_be_ssl    
    # This is how we simulate SSL being on 
    @request.env['HTTPS'] = 'on'
    assert @request.ssl?
    assert_valid_request :get, :must_be_ssl
    @request.env['HTTPS'] = 'off'
  end
  
  def test_get_is_ok_by_default
    assert_valid_request   :get,    :default_method_is_get
    assert_invalid_request :post,   :default_method_is_get
    assert_invalid_request :put,    :default_method_is_get
    assert_invalid_request :delete, :default_method_is_get
  end
  
  def test_enumerated
    assert_valid_request   :get, :enumerated, :color => "blue"
    assert_valid_request   :get, :enumerated, :color => "red"
    assert_valid_request   :get, :enumerated, :color => "green"
    assert_valid_request   :get, :enumerated, :color => "red",   :admin => "true"
    assert_valid_request   :get, :enumerated, :color => "green", :admin => "false"
    assert_invalid_request :get, :enumerated
    assert_invalid_request :get, :enumerated, :color => "bad"
    assert_invalid_request :get, :enumerated, :color => "blue", :admin => "bad"
    assert_invalid_request :get, :enumerated, :admin => "true"
    assert_invalid_request :get, :enumerated, :color => "blue", :admin => "true", :extra => "3"
    assert_invalid_request :get, :enumerated, :color => "true", :admin => "blue"
  end
  
  def test_method_encoded_in_params_should_be_ignored
    assert_valid_request :get, :one_integer, :id => '3'
    assert_valid_request :get, :one_integer, :id => '3', :method => "put"
    assert_valid_request :get, :one_integer, :id => '3', :method => "delete"
  end
  
  def test_collection_required
    assert_valid_request   :get, :collection_required, :person => {"5" => {:name => "Bob"}}    
    assert_valid_request   :get, :collection_required, :person => {"5" => {:name => "Bob"}, "62" => {:name => "Alice"}}    
    assert_valid_request   :get, :collection_required, :person => {"5" => {:name => "Bob"}, "62" => {:name => "Alice"}, "123" => {:name => "Janice"}}    
    assert_invalid_request :get, :collection_required
    assert_invalid_request :get, :collection_required, :person => {:name => "Bob"}
    assert_invalid_request :get, :collection_required, :person => {"a" => {:name => "Bob"}}
    assert_invalid_request :get, :collection_required, :person => {"1" => {:age => "Bob"}}
    assert_invalid_request :get, :collection_required, :person => {"5" => {:name => "Bob"}, :name => "Bob"}
    assert_invalid_request :get, :collection_required, :person => {"5" => {:name => "Bob"}, "a" => {:name => "Bob"}}
    assert_invalid_request :get, :collection_required, :person => {"5" => {:name => "Bob"}, "1" => {:age => "Bob"}}
  end
  
  def test_collection_optional
    assert_valid_request   :get, :collection_optional
    assert_valid_request   :get, :collection_optional, :person => {"5" => {:name => "Bob"}}    
    assert_valid_request   :get, :collection_optional, :person => {"5" => {:name => "Bob"}, "62" => {:name => "Alice"}}    
    assert_valid_request   :get, :collection_optional, :person => {"5" => {:name => "Bob"}, "62" => {:name => "Alice"}, "123" => {:name => "Janice"}}    
    assert_invalid_request :get, :collection_optional, :person => {:name => "Bob"}
    assert_invalid_request :get, :collection_optional, :person => {"a" => {:name => "Bob"}}
    assert_invalid_request :get, :collection_optional, :person => {"1" => {:age => "Bob"}}
    assert_invalid_request :get, :collection_optional, :person => {"5" => {:name => "Bob"}, :name => "Bob"}
    assert_invalid_request :get, :collection_optional, :person => {"5" => {:name => "Bob"}, "a" => {:name => "Bob"}}
    assert_invalid_request :get, :collection_optional, :person => {"5" => {:name => "Bob"}, "1" => {:age => "Bob"}}
  end
  
  def test_collection_of_required_models
    assert_valid_request   :get, :collection_of_required_models, :dog => {"5" => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12'}}
    assert_valid_request   :get, :collection_of_required_models, :dog => {"5" => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12'}, "6" => {:name => 'nittany', :breed => 'shih tzu', :age_in_years => '8'}}
    assert_invalid_request :get, :collection_of_required_models
    assert_invalid_request :get, :collection_of_required_models, :dog => {"5" => {:breed => 'bouvier', :age_in_years => '12'}, "6" => {:name => 'nittany', :breed => 'shih tzu', :age_in_years => '8'}}
    assert_invalid_request :get, :collection_of_required_models, :dog => {"a" => {:breed => 'bouvier', :age_in_years => '12'}, "6" => {:name => 'nittany', :breed => 'shih tzu', :age_in_years => '8'}}
    assert_invalid_request :get, :collection_of_required_models, :dog => {"5" => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12'}, "6" => {:name => 'nittany', :breed => 'shih tzu', :age_in_years => '8', :extra => "bad"}}
  end

  def test_collection_of_optional_models
    assert_valid_request   :get, :collection_of_optional_models
    assert_valid_request   :get, :collection_of_optional_models, :dog => {"5" => {:breed => 'bouvier', :age_in_years => '12'}, "6" => {:name => 'nittany', :breed => 'shih tzu', :age_in_years => '8'}}
    assert_valid_request   :get, :collection_of_optional_models, :dog => {"5" => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12'}}
    assert_valid_request   :get, :collection_of_optional_models, :dog => {"5" => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12'}, "6" => {:name => 'nittany', :breed => 'shih tzu', :age_in_years => '8'}}
    assert_invalid_request :get, :collection_of_optional_models, :dog => {"a" => {:breed => 'bouvier', :age_in_years => '12'}, "6" => {:name => 'nittany', :breed => 'shih tzu', :age_in_years => '8'}}
    assert_invalid_request :get, :collection_of_optional_models, :dog => {"5" => {:name => 'luther', :breed => 'bouvier', :age_in_years => '12'}, "6" => {:name => 'nittany', :breed => 'shih tzu', :age_in_years => '8', :extra => "bad"}}
  end
  
  def test_set_ignore_params
    assert_invalid_request :get, :one_integer, :id => '3', :undefined => '4'
    ValidateRequest::ParamRules.ignore_params << :undefined
    assert_valid_request   :get, :one_integer, :id => '3', :undefined => '4'
    assert_invalid_request :get, :one_integer, :id => '3', :still_undefined => '4'
  end
  
private

  # Works like "get" or "post", only it also asserts that the request was 
  # successfully validated.
  def assert_valid_request(method, url, *args)
    # We need to dup our args, since assert_response seems to add an extra
    # :only_path key to the hash. This looks like a rails bug.
    if args.first
      args2 = [args.first.dup]
    else
      args2 = args.dup
    end
      
    self.send(method.to_s, url.to_s, *args)
    assert_response :success
    self.send(method.to_s, url.to_s + "_with_block", *args2)
    assert_response :success
  rescue ValidateRequest::RequestError => e
    flunk "Received a RequestError exception, but wasn't expecting one: <#{e}>"
  end
  
  # Works like "get" or "post", only it also asserts that we get a failure
  # for the given request.
  def assert_invalid_request(method, url, *args)
    assert_raise(ValidateRequest::RequestError) { self.send(method.to_s, url.to_s, *args) }
    assert_raise(ValidateRequest::RequestError) { self.send(method.to_s, url.to_s + "_with_block", *args) }
  end
  
end
