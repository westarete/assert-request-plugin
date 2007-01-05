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
    assert_valid_request(:get)
    render_text('success')
  end  
  
  def none_with_block
    assert_valid_request do |r|
      r.method :get
    end
    render_text('success')
  end
  
  def one_integer
    assert_valid_request(:get, :id => :integer)
    render_text('success')
  end
  
  def one_integer_with_block
    assert_valid_request do |r|
      r.method   :get
      r.required :id => :integer
    end
    render_text('success')
  end

  def two_integers
    assert_valid_request(:get, :id => :integer, :count => :integer)
    render_text('success')
  end
  
  def two_integers_with_block
    assert_valid_request do |r|
      r.method   :get
      r.required :id => :integer
      r.required :count => :integer
    end
    render_text('success')
  end

  def one_specific
    assert_valid_request(:get, :orientation => 'horizontal')
    render_text('success')
  end
  
  def one_specific_with_block
    assert_valid_request do |r|
      r.method   :get
      r.required :orientation => 'horizontal'
    end
    render_text('success')
  end
  
  
  def one_integer_one_specific
    assert_valid_request(:get, :id => :integer, :orientation => 'horizontal')
    render_text('success')
  end  
  
  def one_integer_one_specific_with_block
    assert_valid_request do |r|
      r.method :get
      r.required :id => :integer, :orientation => 'horizontal'
    end
    render_text('success')
  end  
  
  def get_only
    assert_valid_request(:get)
    render_text('success')
  end

  def get_only_with_block
    assert_valid_request do |r|
      r.method :get
    end
    render_text('success')
  end

  def post_only
    assert_valid_request(:post)
    render_text('success')
  end

  def post_only_with_block
    assert_valid_request do |r|
      r.method :post
    end
    render_text('success')
  end

  def put_only
    assert_valid_request(:put)
    render_text('success')
  end

  def put_only_with_block
    assert_valid_request do |r|
      r.method :put
    end
    render_text('success')
  end

  def get_or_post
    assert_valid_request([:get, :post])
    render_text('success')
  end
  
  def get_or_post_with_block
    assert_valid_request do |r|
      r.method :get, :post
    end
    render_text('success')
  end

  def one_required_integer_one_optional_integer
    assert_valid_request(:get, {:id => :integer}, {:per_page => :integer})
    render_text('success')
  end

  def one_required_integer_one_optional_integer_with_block
    assert_valid_request do |r|
      r.method   :get
      r.required :id       => :integer
      r.optional :per_page => :integer
    end
    render_text('success')
  end

  # Coming Soon!
  # def enumerated_type
  #   assert_valid_request(:get, 
  #                   {:id => :integer},
  #                   {:orientation => ['horizontal', 'vertical']})
  #   render_text('success')    
  # end
  
  def simple_nested
    assert_valid_request(:get, :id => :integer, :page => {:count => :integer})
    render_text('success')
  end
  
  def simple_nested_with_block
    assert_valid_request do |r|
      r.method :get
      r.required :id => :integer
      r.required :page => {:count => :integer}
    end
    render_text('success')
  end
  
  def double_nested
    assert_valid_request(:get, :id => :integer, :page => {:author => {:name => :text}})
    render_text('success')
  end
  
  def double_nested_with_block
    assert_valid_request do |r|
      r.method :get
      r.required :id => :integer
      r.required :page => {:author => {:name => :text}}
    end
    render_text('success')
  end
  
  def double_nested_with_options
    assert_valid_request(:get, 
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
    render_text('success')
  end
  
  def double_nested_with_options_with_block
    assert_valid_request do |r|
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
    render_text('success')
  end
  
  
  def required_dog
    assert_valid_request(:get, {:id => :integer, :dog => Dog})
    render_text('success')
  end
  
  def required_dog_with_block
    assert_valid_request do |r|
      r.method :get
      r.required :id  => :integer
      r.required :dog => Dog
    end
    render_text('success')
  end
  
  def optional_dog
    assert_valid_request(:get, {:id => :integer}, {:dog => Dog})
    render_text('success')
  end
  
  def optional_dog_with_block
    assert_valid_request do |r|
      r.method :get
      r.required :id  => :integer
      r.optional :dog => Dog
    end
    render_text('success')
  end

end
