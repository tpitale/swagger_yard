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
      Hash[authorizations.map {|auth| [auth.id, auth]}]
    end

    private
    def models
      @models ||= parse_models
    end

    def api_groups
      @api_groups ||= parse_controllers
    end

    def parse_models
      ::YARD::Registry.clear
      paths = @model_paths.map { |path| Dir.glob(path.to_s) }.flatten
      ::YARD.parse(paths)
      ::YARD::Registry.all(:class).map do |obj|
        next unless paths.include?(obj.file)
        Model.from_yard_object(obj)
      end.compact.select(&:valid?)
    end

    def parse_controllers
      ::YARD::Registry.clear
      paths = @controller_paths.map { |path| Dir.glob(path.to_s) }.flatten
      ::YARD.parse(paths)
      ::YARD::Registry.all(:class).map do |obj|
        next unless paths.include?(obj.file)
        obj.tags.select {|t| t.tag_name == "authorization"}.each do |t|
          @authorizations << Authorization.from_yard_object(t)
        end
        ApiGroup.from_yard_object(obj)
      end.compact.select(&:valid?)
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
