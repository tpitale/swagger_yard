module SwaggerYard
  class Info
    def to_h
      {
        "title"       => SwaggerYard.config.title,
        "description" => SwaggerYard.config.description,
        "version"     => SwaggerYard.config.api_version
      }
    end
  end

  class Swagger
    attr_reader :specification

    def initialize
      @specification = Specification.new
    end

    def to_h
      metadata.merge(definitions).merge(model_definitions)
    end

    private
    def model_path
      Type::MODEL_PATH
    end

    def definitions
      { "paths"               => paths(specification.path_objects),
        "tags"                => tags(specification.tag_objects),
        "securityDefinitions" => security_defs(specification.security_objects) }
    end

    def model_definitions
      { "definitions" => models(specification.model_objects) }
    end

    def metadata
      {
        "swagger"  => "2.0",
        "info"     => Info.new.to_h
      }.merge(uri_info)
    end

    def uri_info
      uri = URI(SwaggerYard.config.api_base_path)
      host = uri.host
      host = "#{uri.host}:#{uri.port}" unless uri.port == uri.default_port

      {
        'host' => host,
        'basePath' => uri.request_uri,
        'schemes' => [uri.scheme]
      }
    end

    def paths(paths)
      Hash[paths.path_items.map {|path,pi| [path, operations(pi.operations)] }]
    end

    def operations(ops)
      expanded_ops = ops.map do |meth, op|
        op_hash = {
          "tags"        => op.tags,
          "operationId" => op.operation_id,
          "parameters"  => parameters(op.parameters),
          "responses"   => responses(op.responses_by_status, op),
        }

        op_hash["description"] = op.description unless op.description.empty?
        op_hash["summary"]     = op.summary unless op.summary.empty?

        authorizations = op.api_group.authorizations
        unless authorizations.empty?
          op_hash["security"] = authorizations.map {|k,v| { k => v} }
        end

        op_hash.update(op.extended_attributes)

        [meth, op_hash]
      end
      Hash[expanded_ops]
    end

    def parameters(params)
      params.map do |param|
        { "name"        => param.name,
          "description" => param.description,
          "required"    => param.required,
          "in"          => param.param_type
        }.tap do |h|
          schema = param.type.schema_with(model_path: model_path)
          if h["in"] == "body"
            h["schema"] = schema
          else
            h.update(schema)
          end
          h["collectionFormat"] = 'multi' if !Array(param.allow_multiple).empty? && h["items"]
        end
      end
    end

    def responses(responses_by_status, op)
      Hash[responses_by_status.map do |status, resp|
             resp_hash = {}.tap do |h|
               h['description'] = resp && resp.description || op.summary || ''
               h['schema'] = resp.type.schema_with(model_path: model_path) if resp && resp.type
             end
             [status, resp_hash]
           end]
    end

    def models(model_objects)
      model_objects
    end

    def tags(tag_objects)
      tag_objects.sort_by {|t| t.name.upcase }.map do |t|
        { 'name' => t.name, 'description' => t.description }
      end
    end

    def security_defs(security_objects)
      security_objects
    end
  end
end
