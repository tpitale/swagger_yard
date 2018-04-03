require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/.bundle/'
end

ENV["RAILS_ENV"] = "development"

FIXTURE_PATH = Pathname.new(File.expand_path('../fixtures', __FILE__))

require 'bundler/setup'
Bundler.require

require 'rspec/its'
require 'apivore'
# we don't care about these hashie warnings in our test suite
Apivore::Swagger.disable_warnings

require File.expand_path('../../lib/swagger_yard', __FILE__)
require File.expand_path('../fixtures/dummy/config/initializers/swagger_yard.rb', __FILE__)

SwaggerYard.register_custom_yard_tags!

Dir["./spec/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.mock_with :mocha

  config.order = 'random'

  config.include SaveConfig
  config.include YARDHelpers
end
