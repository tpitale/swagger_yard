module SwaggerYard
  class Configuration
    attr_accessor :api_version, :api_base_path
    attr_accessor :swagger_version
    attr_accessor :title, :description
    attr_accessor :controller_path, :model_path
    attr_accessor :path_discovery_function
    attr_accessor :security_definitions
    attr_accessor :include_private

    # openapi-compatible names
    alias_method :openapi_version, :swagger_version
    alias_method :openapi_version=, :swagger_version=
    alias_method :security_schemes, :security_definitions
    alias_method :security_schemes=, :security_definitions=

    def initialize
      @swagger_version = "2.0"
      @api_version = "0.1"
      @title = "Configure title with SwaggerYard.config.title"
      @description = "Configure description with SwaggerYard.config.description"
      @security_definitions = {}
      @external_schema = {}
      @include_private = true
    end

    def external_schema(mappings = nil)
      mappings&.each do |prefix, url|
        @external_schema[prefix.to_s] = url
      end
      @external_schema
    end

    def register_dsl_method(meth, options = {})
      SwaggerYard::Handlers::DSLHandler.register_dsl_method(meth, options)
    end
  end
end
