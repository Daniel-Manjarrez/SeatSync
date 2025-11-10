# spec/rails_helper.rb

# Start SimpleCov before loading any application code
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Helpers', 'app/helpers'
end

# Load RSpec core
require 'spec_helper'

# Set Rails environment to test
ENV['RAILS_ENV'] ||= 'test'

# Load Rails
require_relative '../config/environment'

# Prevent running tests in production
abort("Running in production mode!") if Rails.env.production?

# Load RSpec Rails integration
require 'rspec/rails'

# Load support files
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Configure RSpec
RSpec.configure do |config|
  # Use transactional fixtures (rollback after each test)
  config.use_transactional_fixtures = true

  # Infer spec type from file location (e.g., spec/models = type: :model)
  config.infer_spec_type_from_file_location!

  # Filter Rails from backtraces
  config.filter_rails_from_backtrace!

  # Include file upload helper
  config.include ActionDispatch::TestProcess::FixtureFile
end
