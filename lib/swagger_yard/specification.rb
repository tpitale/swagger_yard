module SwaggerYard
  class Specification
    attr_accessor :authorizations

    def initialize(controller_path = SwaggerYard.config.controller_path,
                   model_path = SwaggerYard.config.model_path)
      @model_paths = [*model_path].compact
      @controller_paths = [*controller_path].compact

      @resource_to_file_path = {}
      @authorizations = []
    end

    def path_objects
      api_groups.map(&:paths).reduce(Paths.new({}), :merge).tap do |paths|
        warn_duplicate_operations(paths)
      end
    end

    # Resources
    def tag_objects
      api_groups.map(&:tag)
    end

    def model_objects
      Hash[models.map {|m| [m.id, m]}]
    end

    def security_objects
      api_groups # triggers controller parsing in case it did not happen before
      Hash[authorizations.map {|auth| [auth.name, auth]}]
    end

    private
    def models
      @models ||= parse_models
    end

    def api_groups
      @api_groups ||= parse_controllers
    end

    def parse_models
      @model_paths.map do |model_path|
        Dir[model_path.to_s].map do |file_path|
          SwaggerYard.yard_class_objects_from_file(file_path).map do |obj|
            Model.from_yard_object(obj)
          end
        end
      end.flatten.compact.select(&:valid?)
    end

    def parse_controllers
      @controller_paths.map do |controller_path|
        Dir[controller_path.to_s].map do |file_path|
          SwaggerYard.yard_class_objects_from_file(file_path).map do |obj|
            obj.tags.select {|t| t.tag_name == "authorization"}.each do |t|
              @authorizations << Authorization.from_yard_object(t)
            end
            ApiGroup.from_yard_object(obj)
          end
        end
      end.flatten.select(&:valid?)
    end

    def warn_duplicate_operations(paths)
      operation_ids = []
      paths.path_items.each do |path,pi|
        pi.operations.each do |_, op|
          if operation_ids.include?(op.operation_id)
            SwaggerYard.log.warn("duplicate operation #{op.operation_id}")
            next
          end
          operation_ids << op.operation_id
        end
      end
    end
  end
end
