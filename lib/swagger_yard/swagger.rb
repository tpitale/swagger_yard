module SwaggerYard
  class Info
    def to_h
      { "title"       => SwaggerYard.config.title,
        "description" => SwaggerYard.config.description,
        "version"     => SwaggerYard.config.api_version }
    end
  end

  class Swagger
    def to_h
      { "swagger"  => "2.0",
        "info"     => Info.new.to_h,
        "host"     => URI(SwaggerYard.config.api_base_path).host,
        "basePath" => URI(SwaggerYard.config.api_base_path).request_uri
      }.merge(ResourceListing.all.to_h)
    end
  end
end
