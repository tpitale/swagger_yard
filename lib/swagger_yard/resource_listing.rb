module SwaggerYard
  class ResourceListing
    attr_accessor :authorizations

    def self.all
      new(SwaggerYard.config.controller_path, SwaggerYard.config.model_path)
    end

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

    def to_h
      { "paths"               => path_objects,
        "definitions"         => model_objects,
        "tags"                => tag_objects,
        "securityDefinitions" => security_objects }
    end

    def path_objects
      controllers.map(&:apis_hash).reduce({}, :merge)
    end

    # Resources
    def tag_objects
      controllers.map(&:to_tag)
    end

    def model_objects
      Hash[models.map {|m| [m.id, m.to_h]}]
    end

    def security_objects
      Hash[authorizations.map {|auth| [auth.name, auth.to_h]}]
    end

    private
    def parse_models
      return [] unless @model_path

      Dir[@model_path].map do |file_path|
        SwaggerYard.yard_class_objects_from_file(file_path).map do |obj|
          Model.from_yard_object(obj)
        end
      end.flatten.compact.select(&:valid?)
    end

    def parse_controllers
      return [] unless @controller_path

      Dir[@controller_path].map do |file_path|
        SwaggerYard.yard_class_objects_from_file(file_path).map do |obj|
          obj.tags.select {|t| t.tag_name == "authorization"}.each do |t|
            @authorizations << Authorization.from_yard_object(t)
          end
          ApiDeclaration.from_yard_object(obj)
        end
      end.flatten.select(&:valid?)
    end
  end
end
