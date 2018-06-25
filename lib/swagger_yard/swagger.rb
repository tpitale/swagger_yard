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
      { "paths"               => paths(specification.path_objects),
        "definitions"         => models(specification.model_objects),
        "tags"                => tags(specification.tag_objects),
        "securityDefinitions" => security_defs(specification.security_objects) }
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
      Hash[paths.path_items.map {|path,pi| [path, pi.operations_hash] }]
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
