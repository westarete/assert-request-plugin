# validate_request Rails Plugin
#
# (c) Copyright 2006 by West Arete Computing, Inc.

# Simple model to use while testing ActiveRecord requirement types.
class Dog < ActiveRecord::Base ; end

# A controller with fake actions that we can call to test their different
# request requirements. All actions render the text 'success' if the 
# request was deemed to be valid, and redirect if the request was deemed to
# be invalid.
class ValidateRequestController < ActionController::Base
  include ValidateRequest
    
  def none
    assert_request(:get)
    render :nothing => true
  end  
  
  def none_with_block
    assert_request do |r|
      r.method :get
    end
    render :nothing => true
  end
  
  def one_integer
    assert_request(:get, :id => :integer)
    render :nothing => true
  end
  
  def one_integer_with_block
    assert_request do |r|
      r.method   :get
      r.required :id => :integer
    end
    render :nothing => true
  end

  def two_integers
    assert_request(:get, :id => :integer, :count => :integer)
    render :nothing => true
  end
  
  def two_integers_with_block
    assert_request do |r|
      r.method   :get
      r.required :id => :integer
      r.required :count => :integer
    end
    render :nothing => true
  end

  def one_specific
    assert_request(:get, :orientation => 'horizontal')
    render :nothing => true
  end
  
  def one_specific_with_block
    assert_request do |r|
      r.method   :get
      r.required :orientation => 'horizontal'
    end
    render :nothing => true
  end
  
  
  def one_integer_one_specific
    assert_request(:get, :id => :integer, :orientation => 'horizontal')
    render :nothing => true
  end  
  
  def one_integer_one_specific_with_block
    assert_request do |r|
      r.method :get
      r.required :id => :integer, :orientation => 'horizontal'
    end
    render :nothing => true
  end  
  
  def get_only
    assert_request(:get)
    render :nothing => true
  end

  def get_only_with_block
    assert_request do |r|
      r.method :get
    end
    render :nothing => true
  end

  def post_only
    assert_request(:post)
    render :nothing => true
  end

  def post_only_with_block
    assert_request do |r|
      r.method :post
    end
    render :nothing => true
  end

  def put_only
    assert_request(:put)
    render :nothing => true
  end

  def put_only_with_block
    assert_request do |r|
      r.method :put
    end
    render :nothing => true
  end

  def get_or_post
    assert_request([:get, :post])
    render :nothing => true
  end
  
  def get_or_post_with_block
    assert_request do |r|
      r.method :get, :post
    end
    render :nothing => true
  end

  def one_required_integer_one_optional_integer
    assert_request(:get, {:id => :integer}, {:per_page => :integer})
    render :nothing => true
  end

  def one_required_integer_one_optional_integer_with_block
    assert_request do |r|
      r.method   :get
      r.required :id       => :integer
      r.optional :per_page => :integer
    end
    render :nothing => true
  end

  # Coming Soon!
  # def enumerated_type
  #   assert_request(:get, 
  #                   {:id => :integer},
  #                   {:orientation => ['horizontal', 'vertical']})
  #   render :nothing => true    
  # end
  
  def simple_nested
    assert_request(:get, :id => :integer, :page => {:count => :integer})
    render :nothing => true
  end
  
  def simple_nested_with_block
    assert_request do |r|
      r.method :get
      r.required :id => :integer
      r.required :page => {:count => :integer}
    end
    render :nothing => true
  end
  
  def double_nested
    assert_request(:get, :id => :integer, :page => {:author => {:name => :text}})
    render :nothing => true
  end
  
  def double_nested_with_block
    assert_request do |r|
      r.method :get
      r.required :id => :integer
      r.required :page => {:author => {:name => :text}}
    end
    render :nothing => true
  end
  
  def double_nested_with_options
    assert_request(:get, 
      {
        :id => :integer, 
        :page => {
          :author => {:name => :text},
        },
      },
      {
        :page => {
          :author => {:optional_email => :text},
          :optional_orientation => :text,
          :optional_coauthor => {
            :optional_name => :text,
            :optional_email => :text,
          },
        },        
      }
    )
    render :nothing => true
  end
  
  def double_nested_with_options_with_block
    assert_request do |r|
      r.method   :get
      r.required :id => :integer
      r.required :page => {:author => {:name => :text}}
      r.optional :page => {
          :author => {:optional_email => :text},
          :optional_orientation => :text,
          :optional_coauthor => {
            :optional_name => :text,
            :optional_email => :text,
          }
        }
    end
    render :nothing => true
  end
  
  
  def required_dog
    assert_request(:get, {:id => :integer, :dog => Dog})
    render :nothing => true
  end
  
  def required_dog_with_block
    assert_request do |r|
      r.method :get
      r.required :id  => :integer
      r.required :dog => Dog
    end
    render :nothing => true
  end
  
  def optional_dog
    assert_request(:get, {:id => :integer}, {:dog => Dog})
    render :nothing => true
  end
  
  def optional_dog_with_block
    assert_request do |r|
      r.method :get
      r.required :id  => :integer
      r.optional :dog => Dog
    end
    render :nothing => true
  end
  
  def must_be_ssl
    assert_request(:get, {}, {}, :https)
    render :nothing => true
  end
  
  def must_be_ssl_with_block
    assert_request do |r|
      r.method :get
      r.protocol :https
    end
    render :nothing => true
  end
  
  def default_method_is_get
    assert_request
    render :nothing => true
  end

  def default_method_is_get_with_block
    assert_request do |r|
    end
    render :nothing => true
  end

end
