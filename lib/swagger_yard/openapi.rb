module SwaggerYard
  class OpenAPI < Swagger
    def to_h
      metadata.merge(definitions)
    end

    def model_path
      '#/components/schemas/'
    end

    def metadata
      {
        'openapi' => '3.0.0',
        'info' => Info.new.to_h,
        'servers' => [{'url' => SwaggerYard.config.api_base_path}]
      }
    end

    def definitions
      {
        "paths" => paths(specification.path_objects),
        "tags" => tags(specification.tag_objects),
        "components" => components
      }
    end

    def components
      {
        "schemas" => models(specification.model_objects),
        "securitySchemes" => security_defs(specification.security_objects)
      }
    end

    def parameters(params)
      params.select { |param| param.param_type != 'body' }.map do |param|
        { "name"        => param.name,
          "description" => param.description,
          "required"    => param.required,
          "in"          => param.param_type
        }.tap do |h|
          schema = param.type.schema_with(model_path: model_path)
          h["schema"] = schema
          h["explode"] = true if !Array(param.allow_multiple).empty? && schema["items"]
        end
      end
    end

    def operation(op)
      op_hash = super
      if body_param = op.parameters.detect { |p| p.param_type == 'body' }
        op_hash['requestBody'] = {
          'description' => body_param.description,
          'content' => {
            'application/json' => {
              'schema' => body_param.type.schema_with(model_path: model_path)
            }
          }
        }
      end
      op_hash
    end

    def response(resp, op)
      {}.tap do |h|
        h['description'] = resp && resp.description || op.summary || ''
        if resp && resp.type && (schema = resp.type.schema_with(model_path: model_path))
          h['content'] = { 'application/json' => { 'schema' => schema } }
        end
      end
    end
  end
end
