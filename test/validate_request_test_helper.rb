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
    
  @@redirect_for_bad_request = '/error'
  
  def none
    validate_request(:get) or return
    render_text('success')
  end  
  
  def one_integer
    validate_request(:get, :id => :integer) or return
    render_text('success')
  end
  
  def two_integers
    validate_request(:get, :id => :integer, :count => :integer) or return
    render_text('success')
  end
  
  def one_specific
    validate_request(:get, :orientation => 'horizontal') or return
    render_text('success')
  end
  
  def one_integer_one_specific
    validate_request(:get, :id => :integer, :orientation => 'horizontal') or return
    render_text('success')
  end  
  
  def get_only
    validate_request(:get) or return
    render_text('success')
  end

  def post_only
    validate_request(:post) or return
    render_text('success')
  end

  def put_only
    validate_request(:put) or return
    render_text('success')
  end

  def get_or_post
    validate_request([:get, :post]) or return
    render_text('success')
  end
  
  def one_required_integer_one_optional_integer
    validate_request(:get, {:id => :integer}, {:per_page => :integer}) or return
    render_text('success')
  end

  # Coming Soon!
  # def enumerated_type
  #   validate_request(:get, 
  #                   {:id => :integer},
  #                   {:orientation => ['horizontal', 'vertical']}) or return
  #   render_text('success')    
  # end
  
  def simple_nested
    validate_request(:get, :id => :integer, :page => {:count => :integer}) or return
    render_text('success')
  end
  
  def double_nested
    validate_request(:get, :id => :integer, :page => {:author => {:name => :text}}) or return
    render_text('success')
  end
  
  def double_nested_with_options
    validate_request(:get, 
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
    ) or return
    render_text('success')
  end
  
  def required_dog
    validate_request(:get, {:id => :integer, :dog => Dog}) or return
    render_text('success')
  end
  
  def optional_dog
    validate_request(:get, {:id => :integer}, {:dog => Dog}) or return
    render_text('success')
  end
  
end
