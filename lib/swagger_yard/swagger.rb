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
    def to_h
      {
        "swagger"  => "2.0",
        "info"     => Info.new.to_h
      }.merge(uri_info).merge(Specification.new.to_h)
    end

    private

    def uri_info
      uri = URI(SwaggerYard.config.api_base_path)
      host = uri.host
      host = "#{uri.host}:#{uri.port}" unless uri.port == uri.default_port

      {
        'host' => host,
        'basePath' => uri.request_uri
      }
    end
  end
end
