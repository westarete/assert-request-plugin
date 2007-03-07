# validate_request Rails Plugin
#
# (c) Copyright 2006 by West Arete Computing, Inc.

# Simple model to use while testing ActiveRecord requirement types.
class Dog < ActiveRecord::Base ; end

# A controller with fake actions that we can call to test their different
# request was deemed to be valid, and redirect if the request was deemed to
# be invalid.
class ValidateRequestController < ActionController::Base
  include ValidateRequest

  # Redefine the "render" method to render nothing, so that we don't have
  # to create views for our actions or call "render :nothing => true" at the
  # end of each one. We can't do this with a filter, since calling render 
  # within a filter causes the action to be skipped.
  def render_with_force_nothing
    render_without_force_nothing :nothing => true
  end    
  alias_method_chain :render, :force_nothing
  
  # And now, the actions that will be available to the tests...
  
  def none
    assert_request do |r|
      r.method :get
    end
  end  
  
  def one_integer
    assert_request do |r|
      r.method   :get
      r.required "id" => :integer
    end
  end

  def two_integers
    assert_request do |r|
      r.method   :get
      r.required "id" => :integer
      r.required "count" => :integer
    end
  end

  def one_specific
    assert_request do |r|
      r.method   :get
      r.required "orientation" => 'horizontal'
    end
  end
  
  def one_integer_one_specific
    assert_request do |r|
      r.method :get
      r.required "id" => :integer, "orientation" => 'horizontal'
    end
  end  
  
  def get_only
    assert_request do |r|
      r.method :get
    end
  end

  def post_only
    assert_request do |r|
      r.method :post
    end
  end

  def put_only
    assert_request do |r|
      r.method :put
    end
  end

  def get_or_post
    assert_request do |r|
      r.method :get, :post
    end
  end

  def one_required_integer_one_optional_integer
    assert_request do |r|
      r.method   :get
      r.required "id"       => :integer
      r.optional "per_page" => :integer
    end
  end
  
  def simple_nested
    assert_request do |r|
      r.method :get
      r.required "id" => :integer
      r.required "page" => {"count" => :integer}
    end
  end
  
  def double_nested
    assert_request do |r|
      r.method :get
      r.required "id" => :integer
      r.required "page" => {"author" => {"name" => :string}}
    end
  end
    
  def double_nested_with_options
    assert_request do |r|
      r.method   :get
      r.required "id" => :integer
      r.required "page" => {"author" => {"name" => :string}}
      r.optional "page" => {
          "author" => {"optional_email" => :string},
          "optional_orientation" => :string,
          "optional_coauthor" => {
            "optional_name" => :string,
            "optional_email" => :string,
          }
        }
    end
  end
    
  def required_dog
    assert_request do |r|
      r.method :get
      r.required "id"  => :integer
      r.required "dog" => Dog
    end
  end
    
  def optional_dog
    assert_request do |r|
      r.method :get
      r.required "id"  => :integer
      r.optional "dog" => Dog
    end
  end
    
  def must_be_ssl
    assert_request do |r|
      r.method :get
      r.protocol :https
    end
  end
  
  def default_method_is_get
    assert_request do |r|
    end
  end
  
  def enumerated
    assert_request do |r|
      r.required "color" => ["red", "blue", "green"]
      r.optional "admin" => ["true", "false"]
    end
  end

  def collection_required
    assert_request do |r|
      r.required "person" => {[] => {"name" => :string}}
    end
  end

  def collection_optional
    assert_request do |r|
      r.optional "person" => {[] => {"name" => :string}}
    end
  end
      
  def collection_of_required_models
    assert_request do |r|
      r.required "dog" => {[] => Dog}
    end
  end
    
  def collection_of_optional_models
    assert_request do |r|
      r.optional "dog" => {[] => Dog}
    end
  end

end
