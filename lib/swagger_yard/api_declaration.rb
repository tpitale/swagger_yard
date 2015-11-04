module SwaggerYard
  class ApiDeclaration
    attr_accessor :description, :resource, :resource_path
    attr_reader :apis, :authorizations

    def self.from_yard_object(resource_listing, yard_object)
      new(resource_listing).add_yard_object(yard_object)
    end

    def initialize(resource_listing)
      @resource_listing = resource_listing
      @resource         = nil
      @apis             = {}
      @authorizations   = {}
    end

    def valid?
      !@resource.nil?
    end

    def add_yard_object(yard_object)
      case yard_object.type
      when :class # controller
        add_info(yard_object)
        if valid?
          yard_object.children.each do |child_object|
            add_yard_object(child_object)
          end
        end
      when :method # actions
        add_api(yard_object)
      end
      self
    end

    def add_info(yard_object)
      @description = yard_object.docstring

      if tag = yard_object.tags.detect {|t| t.tag_name == "resource"}
        @resource = tag.text
      end

      if tag = yard_object.tags.detect {|t| t.tag_name == "resource_path"}
        @resource_path = tag.text.downcase
      end

      # we only have api_key auth, the value for now is always empty array
      @authorizations = Hash[yard_object.tags.
                             select {|t| t.tag_name == "authorize_with"}.
                             map(&:text).uniq.
                             map {|k| [k, []]}]

      # HACK, requires knowledge of resource_listing
      yard_object.tags.select {|t| t.tag_name == "authorization"}.each do |t|
        @resource_listing.authorizations << Authorization.from_yard_object(t)
      end
    end

    def add_api(yard_object)
      path = Api.path_from_yard_object(yard_object)

      return if path.nil?

      api = (apis[path] ||= Api.from_yard_object(yard_object, self))
      api.add_operation(yard_object)
    end

    def apis_hash
      Hash[apis.map {|path, api| [path, api.operations_hash]}]
    end

    def to_tag
      { "name"        => resource,
        "description" => description }
    end
  end
end
