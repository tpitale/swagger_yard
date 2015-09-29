require 'simplecov'
SimpleCov.start

ENV["RAILS_ENV"] = "development"

require 'bundler/setup'
Bundler.require

# Load Rails, which loads our swagger_yard
# require File.expand_path('../fixtures/dummy/config/application.rb', __FILE__)

require File.expand_path('../../lib/swagger_yard', __FILE__)
require File.expand_path('../fixtures/dummy/config/initializers/swagger_yard.rb', __FILE__)

SwaggerYard.register_custom_yard_tags!

Dir["./spec/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.mock_with :mocha

  config.order = 'random'
end
