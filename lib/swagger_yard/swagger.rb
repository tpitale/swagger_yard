module SwaggerYard
  class Info
    def to_h
      {
        "title" => SwaggerYard.config.title,
        "description" => SwaggerYard.config.description,
        "version" => SwaggerYard.config.api_version
      }
    end
  end

  class Swagger
    class << self; alias_method :object_new, :new; end

    def self.new(*args)
      return OpenAPI.object_new(*args) if SwaggerYard.config.swagger_version.start_with?("3.0")
      super
    end

    attr_reader :specification

    def initialize(spec = Specification.new)
      @specification = spec
    end

    def to_h
      metadata.merge(definitions).merge(model_definitions)
    end

    private

    def model_path
      Type::MODEL_PATH
    end

    def definitions
      {"paths" => paths(specification.path_objects),
       "tags" => tags(specification.tag_objects),
       "securityDefinitions" => security_defs(specification.security_objects)}
    end

    def model_definitions
      {"definitions" => models(specification.model_objects)}
    end

    def metadata
      {
        "swagger" => "2.0",
        "info" => Info.new.to_h
      }.merge(uri_info)
    end

    def uri_info
      uri = URI(SwaggerYard.config.api_base_path)
      host = uri.host
      host = "#{uri.host}:#{uri.port}" unless uri.port == uri.default_port

      {
        "host" => host,
        "basePath" => uri.request_uri,
        "schemes" => [uri.scheme]
      }
    end

    def paths(paths)
      paths.path_items.map { |path, pi| [path, operations(pi.operations)] }.to_h
    end

    def operations(ops)
      expanded_ops = ops.map do |meth, op|
        [meth, operation(op)]
      end
      expanded_ops.to_h
    end

    def operation(op)
      op_hash = {
        "tags" => op.tags,
        "operationId" => op.operation_id,
        "parameters" => parameters(op.parameters),
        "responses" => responses(op.responses_by_status, op)
      }

      op_hash["description"] = op.description unless op.description.empty?
      op_hash["summary"] = op.summary unless op.summary.empty?

      authorizations = op.api_group.authorizations
      unless authorizations.empty?
        op_hash["security"] = authorizations.map { |k, v| {k => v} }
      end

      op_hash.update(op.extended_attributes)
    end

    def parameters(params)
      params.map do |param|
        {"name" => param.name,
         "description" => param.description,
         "required" => param.required,
         "in" => param.param_type}.tap do |h|
          schema = param.type.schema_with(model_path: model_path)
          if h["in"] == "body"
            h["schema"] = schema
          else
            h.update(schema)
          end
          h["collectionFormat"] = "multi" if !Array(param.allow_multiple).empty? && h["items"]
        end
      end
    end

    def responses(responses_by_status, op)
      responses_by_status.map { |status, resp| [status, response(resp, op)] }.to_h
    end

    def response(resp, op)
      {}.tap do |h|
        h["description"] = resp && resp.description || op.summary || ""
        h["schema"] = resp.type.schema_with(model_path: model_path) if resp && resp.type
        if resp && resp.example
          h["examples"] = {
            "application/json" => resp.example
          }
        end
      end
    end

    def models(model_objects)
      model_objects.map { |name, mod| [name, model(mod)] }.to_h
    end

    def model(mod)
      h = {}

      if !mod.properties.empty? || mod.inherits.empty?
        h["type"] = "object"
        h["properties"] = mod.properties.map { |p| [p.name, property(p)] }.to_h
        h["required"] = mod.properties.select(&:required?).map(&:name) if mod.properties.detect(&:required?)
      end

      h["discriminator"] = mod.discriminator if mod.discriminator

      # Polymorphism
      unless mod.inherits.empty?
        all_of = mod.inherits.map { |name| Type.new(name).schema_with(model_path: model_path) }
        all_of << h unless h.empty?

        if all_of.length == 1 && mod.description.empty?
          h.update(all_of.first)
        else
          h = {"allOf" => all_of}
        end
      end

      # Description
      h["description"] = mod.description unless mod.description.empty?

      h["example"] = mod.example if mod.example

      h["additionalProperties"] = mod.additional_properties if !mod.additional_properties.nil?
      h
    end

    def property(prop)
      prop.type.schema_with(model_path: model_path).tap do |h|
        unless h["$ref"]
          h["description"] = prop.description if prop.description && !prop.description.strip.empty?
          if prop.nullable
            h["x-nullable"] = true
            if h["type"]
              h["type"] = [h["type"], "null"]
            end
          end
          h["example"] = prop.example if prop.example
        end
      end
    end

    def tags(tag_objects)
      tag_objects.sort_by { |t| t.name.upcase }.map do |t|
        {"name" => t.name, "description" => t.description}
      end
    end

    def security_defs(security_objects)
      config_defs = SwaggerYard.config.security_definitions
      config_defs.merge(security_objects.map { |name, obj| [name, security(obj)] }.to_h)
    end

    def security(obj)
      case obj.type
      when /api_?key/i
        {"type" => "apiKey", "name" => obj.key, "in" => obj.name}
      else
        {"type" => "basic"}
      end.tap do |result|
        result["description"] = obj.description if obj.description && !obj.description.empty?
      end
    end
  end
end
