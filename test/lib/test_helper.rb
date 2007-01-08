# Boot the environment for testing this plugin.

require 'test/unit'
RAILS_ENV = 'test'

PLUGIN_ROOT = File.dirname(__FILE__) + '/../..'
RAILS_ROOT = PLUGIN_ROOT + '/../../..'
$:.unshift(PLUGIN_ROOT + '/lib')

# Run the tests using the same environment that the application uses.
require File.expand_path(RAILS_ROOT + '/config/environment.rb')

# For functional tests.
require 'action_controller/test_process'

# Set up the test database.
config = YAML::load(IO.read(PLUGIN_ROOT + '/test/config/database.yml'))
ActionController::Base.logger = ActiveRecord::Base.logger = Logger.new(PLUGIN_ROOT + '/test/log/schema.log')
ActiveRecord::Base.establish_connection(config[RAILS_ENV])
schema_file = PLUGIN_ROOT + '/test/db/schema.rb'
load(schema_file) if File.exist?(schema_file)
