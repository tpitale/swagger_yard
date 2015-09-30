module SwaggerYard
  class ResourceListing
    attr_reader :api_declarations, :resource_to_file_path
    attr_accessor :authorizations

    def initialize(controller_path, model_path)
      @model_path = model_path
      @controller_path = controller_path

      @resource_to_file_path = {}
      @authorizations = []
    end

    def models
      @models ||= parse_models
    end

    def controllers
      @controllers ||= parse_controllers
    end

    def declaration_for(resource_name)
      controllers[resource_name]
    end

    def to_h
      {
        "apiVersion"      => SwaggerYard.config.api_version,
        "swaggerVersion"  => SwaggerYard.config.swagger_version,
        "basePath"        => SwaggerYard.config.swagger_spec_base_path,
        "apis"            => list_api_declarations,
        "authorizations"  => authorizations_hash
      }
    end

    def swagger_v2
      { paths:               path_objects,
        definitions:         model_objects,
        tags:                tag_objects,
        securityDefinitions: security_objects }
    end

    def path_objects
      operations = controllers.values.flat_map do |api_decl|
        api_decl.apis.values.flat_map(&:operations)
      end
      operations.inject({}) do |hsh, op|
        hsh.deep_merge(op.path => op.swagger_v2)
      end
    end

    def model_objects
      models.inject({}) {|h,m| h.merge(m.id => m.swagger_v2)}
    end

    def tag_objects
      controllers.values.flat_map do |api_decl|
        { name: api_decl.resource,
          description: api_decl.description }
      end
    end

    def security_objects
      authorizations.inject({}) {|h,auth| h[auth.name] = auth.swagger_v2; h }
    end

  private
    def list_api_declarations
      controllers.values.sort_by(&:resource_path).map(&:listing_hash)
    end

    def parse_models
      return [] unless @model_path

      Dir[@model_path].map do |file_path|
        Model.from_yard_objects(SwaggerYard.yard_objects_from_file(file_path))
      end.compact.select(&:valid?)
    end

    def parse_controllers
      return {} unless @controller_path

      Hash[Dir[@controller_path].map do |file_path|
        declaration = create_api_declaration(file_path)

        [declaration.resource_name, declaration] if declaration.valid?
      end.compact]
    end

    def create_api_declaration(file_path)
      yard_objects = SwaggerYard.yard_objects_from_file(file_path)

      ApiDeclaration.new(self).add_yard_objects(yard_objects)
    end

    def authorizations_hash
      Hash[
        authorizations.map(&:name).zip(authorizations.map(&:to_h)) # ugh
      ]
    end
  end
end
