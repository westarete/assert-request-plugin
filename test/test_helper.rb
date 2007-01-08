# Configure the environment for testing this plugin.

# Set ourselves up for testing ../lib
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'test/unit'
RAILS_ENV = 'test'

# Run the tests using the same environment that the application uses.
require File.expand_path(File.join(File.dirname(__FILE__), '/../../../../config/environment.rb'))
require 'action_controller/test_process'

# Set up the test database.
config = YAML::load(IO.read(File.dirname(__FILE__) + '/config/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/log/schema.log")
ActiveRecord::Base.establish_connection(config['test'])
load(File.dirname(__FILE__) + "/db/schema.rb") if File.exist?(File.dirname(__FILE__) + "/db/schema.rb")