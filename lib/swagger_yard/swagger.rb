module SwaggerYard
  class Info
    def swagger_v2
      { "title"       => SwaggerYard.config.title,
        "description" => SwaggerYard.config.description,
        "version"     => SwaggerYard.config.api_version }
    end
  end

  class Swagger
    def swagger_v2
      { "swagger"  => "2.0",
        "info"     => Info.new.swagger_v2,
        "host"     => URI(SwaggerYard.config.api_base_path).host,
        "basePath" => URI(SwaggerYard.config.api_base_path).request_uri
      }.merge(ResourceListing.all.swagger_v2)
    end
  end
end
