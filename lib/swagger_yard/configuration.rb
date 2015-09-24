module SwaggerYard
  class Configuration
    attr_accessor :swagger_spec_base_path, :api_base_path, :api_path
    attr_accessor :swagger_version, :api_version
    attr_accessor :title, :description
    attr_accessor :enable, :reload

    def initialize
      self.swagger_version = "1.1"
      self.api_version = "0.1"
      self.enable = false
      self.reload = true
      self.title = "Configure title with SwaggerYard.config.title"
      self.description = "Configure description with SwaggerYard.config.description"
    end
  end
end
