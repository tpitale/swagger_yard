module SwaggerYard
  class ApiDeclaration
    attr_accessor :description, :resource
    attr_reader :apis, :authorizations, :class_name

    def self.from_yard_object(yard_object)
      new.add_yard_object(yard_object)
    end

    def initialize
      @resource         = nil
      @apis             = {}
      @authorizations   = {}
    end

    def valid?
      !@resource.nil?
    end

    def add_yard_object(yard_object)
      return self if yard_object.visibility == :private && !SwaggerYard.config.include_private
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
      @class_name  = yard_object.path

      if tag = yard_object.tags.detect {|t| t.tag_name == "resource"}
        @resource = tag.text
      end

      if tag = yard_object.tags.detect {|t| t.tag_name == "resource_path"}
        log.warn "DEPRECATED: @resource_path tag is obsolete."
      end

      # we only have api_key auth, the value for now is always empty array
      @authorizations = Hash[yard_object.tags.
                             select {|t| t.tag_name == "authorize_with"}.
                             map(&:text).uniq.
                             map {|k| [k, []]}]
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
