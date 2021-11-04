SwaggerYard.configure do |config|
  config.swagger_version = "2.0"
  config.api_version = "1.0"
  config.api_base_path = "http://localhost:3000/api"
  config.controller_path = File.expand_path("../../../app/controllers/**/*", __FILE__)
  config.model_path = File.expand_path("../../../app/models/**/*", __FILE__)
end
