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
      metadata.merge(definitions)
    end

    private
    def definitions
      { "paths"               => specification.path_objects,
        "definitions"         => specification.model_objects,
        "tags"                => specification.tag_objects,
        "securityDefinitions" => specification.security_objects }
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
  end
end
