module SwaggerYard
  class Info
    def to_json
      { title: SwaggerYard.config.title,
        description: SwaggerYard.config.description,
        version: SwaggerYard.config.api_version }
    end
  end

  class Swagger
    def to_json
      { swagger: "2.0",
        info: Info.new.to_json,
        host: URI(SwaggerYard.config.api_base_path).host,
        basePath: URI(SwaggerYard.config.api_base_path).request_uri,
        paths: {}
        }
    end
  end
end
