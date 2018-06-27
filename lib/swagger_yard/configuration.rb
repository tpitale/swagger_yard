module SwaggerYard
  class Configuration
    attr_accessor :api_version, :api_base_path
    attr_accessor :swagger_version
    attr_accessor :title, :description
    attr_accessor :controller_path, :model_path
    attr_accessor :path_discovery_function
    attr_accessor :security_definitions

    # openapi-compatible names
    alias openapi_version swagger_version
    alias openapi_version= swagger_version=
    alias security_schemes security_definitions
    alias security_schemes= security_definitions=

    def initialize
      @swagger_version = "2.0"
      @api_version = "0.1"
      @title = "Configure title with SwaggerYard.config.title"
      @description = "Configure description with SwaggerYard.config.description"
      @security_definitions = {}
      @external_schema = {}
    end

    def external_schema(mappings = nil)
      mappings.each do |prefix, url|
        @external_schema[prefix.to_s] = url
      end if mappings
      @external_schema
    end
  end
end
