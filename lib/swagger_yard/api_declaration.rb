module SwaggerYard
  class ApiDeclaration
    attr_accessor :description, :resource_path
    attr_reader :apis

    def initialize(resource_listing)
      @resource_listing = resource_listing

      @apis   = {}
      @model_names = []
    end

    def valid?
      !@resource_path.nil?
    end

    def add_yard_objects(yard_objects)
      yard_objects.each do |yard_object|
        add_yard_object(yard_object)
      end
      self
    end

    def add_yard_object(yard_object)
      case yard_object.type
      when :class
        add_listing_info(ListingInfo.new(yard_object))
      when :method
        add_api(Api.new(@resource_listing, yard_object))
      end
    end

    def add_listing_info(listing_info)
      @description = listing_info.description
      @resource_path = listing_info.resource_path
    end

    def add_api(api)
      return unless api.valid?

      @model_names += api.model_names

      if @apis.keys.include?(api.path)
        same_api_path = @apis[api.path]
        same_api_path["operations"] << api.operation
        @apis[api.path] = same_api_path
      else
        @apis[api.path] = api.to_h
      end
    end

    def resource_name
      @resource_path
    end

    def models
      @resource_listing.models.select {|m| @model_names.include?(m.id)}
    end

    def to_h
      {
        "apiVersion"     => SwaggerYard.config.api_version,
        "swaggerVersion" => SwaggerYard.config.swagger_version,
        "basePath"       => SwaggerYard.config.api_base_path,
        "resourcePath"   => resource_path,
        "apis"           => apis.values,
        "models"         => models.inject({}) do |models_hash, model|
                              models_hash.merge!(model.to_h)
                            end
      }
    end

    def listing_hash
      {
        "path"        => resource_path,
        "description" => description
      }
    end
  end
end
