# Boot the environment for testing this plugin.

# Make sure we haven't already initialized.
unless defined? PLUGIN_ROOT
  require 'test/unit'
  RAILS_ENV = 'test'

  PLUGIN_ROOT = File.dirname(__FILE__) + '/..'
  RAILS_ROOT = PLUGIN_ROOT + '/../../..'

  # Run the tests using the same environment that the application uses.
  require File.expand_path(RAILS_ROOT + '/config/environment.rb')

  # For functional tests.
  require 'action_controller/test_process'

  # Set up the test database.
  config = YAML::load(IO.read(PLUGIN_ROOT + '/config/database.yml'))
  ActionController::Base.logger = ActiveRecord::Base.logger = Logger.new(PLUGIN_ROOT + "/log/#{RAILS_ENV}.log")
  ActiveRecord::Base.establish_connection(config[RAILS_ENV])
  schema_file = PLUGIN_ROOT + '/db/schema.rb'
  load(schema_file) if File.exist?(schema_file)
end

class Test::Unit::TestCase
  # The opposite of assert_raise
  def assert_not_raise(exception, &block)
    yield
    assert true
  rescue exception => e
    flunk "Received a #{exception.to_s} exception, but wasn't expecting one: #{e}"
  end
end

# Simple model to use while testing ActiveRecord requirement types.
class Dog < ActiveRecord::Base ; end

# Redefine the "render" method to render nothing, so that we don't have
# to create views for our actions or call "render :nothing => true" at the
# end of each one. We can't do this with a filter, since calling render 
# within a filter causes the action to be skipped.
class ActionController::Base
  def render_with_force_nothing
    render_without_force_nothing :nothing => true
  end    
  alias_method_chain :render, :force_nothing
end