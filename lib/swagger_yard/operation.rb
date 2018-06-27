module SwaggerYard
  class Response
    attr_accessor :status, :description, :type
  end

  class Operation
    attr_accessor :description, :ruby_method
    attr_writer :summary
    attr_reader :path, :http_method
    attr_reader :parameters
    attr_reader :path_item, :responses, :default_response

    # TODO: extract to operation builder?
    def self.from_yard_object(yard_object, path_item)
      new(path_item).tap do |operation|
        operation.ruby_method = yard_object.name(false)
        operation.description = yard_object.docstring
        yard_object.tags.each do |tag|
          case tag.tag_name
          when "path"
            tag = SwaggerYard.requires_type(tag)
            operation.add_path_params_and_method(tag) if tag
          when "parameter"
            operation.add_parameter(tag)
          when "response_type"
            tag = SwaggerYard.requires_type(tag)
            operation.add_response_type(Type.from_type_list(tag.types), tag.text) if tag
          when "error_message", "response"
            operation.add_response(tag)
          when "summary"
            operation.summary = tag.text
          end
        end

        operation.sort_parameters
      end
    end

    def initialize(path_item)
      @path_item      = path_item
      @summary        = nil
      @description    = ""
      @parameters     = []
      @default_response = nil
      @responses = []
    end

    def summary
      @summary || description.split("\n\n").first || ""
    end

    def operation_id
      "#{api_group.resource}-#{ruby_method}"
    end

    def api_group
      path_item.api_group
    end

    def tags
      [api_group.resource].compact
    end

    def responses_by_status
      {}.tap do |hash|
        hash['default'] = default_response
        responses.each do |response|
          hash[response.status] = response
        end
      end
    end

    def extended_attributes
      {}.tap do |h|
        # Rails controller/action: if constantize/controller_path methods are
        # unavailable or constant is not defined, catch exception and skip these
        # attributes.
        begin
          h["x-controller"] = api_group.class_name.constantize.controller_path.to_s
          h["x-action"]     = ruby_method.to_s
        rescue NameError, NoMethodError
        end
      end
    end

    ##
    # Example: [GET] /api/v2/ownerships
    # Example: [PUT] /api/v1/accounts/{account_id}
    def add_path_params_and_method(tag)
      if @path && @http_method
        SwaggerYard.log.warn 'multiple path tags not supported: ' \
          "ignored [#{tag.types.first}] #{tag.text}"
        return
      end

      @path = tag.text
      @http_method = tag.types.first

      parse_path_params(tag.text).each do |name|
        add_or_update_parameter Parameter.from_path_param(name)
      end
    end

    ##
    # Example: [Array]     status            Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Array]     status(required)  Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Array]     status(required, body)  Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Integer]   media[media_type_id]                          ID of the desired media type.
    def add_parameter(tag)
      param = Parameter.from_yard_tag(tag)
      add_or_update_parameter param if param
    end

    def add_or_update_parameter(parameter)
      if existing = @parameters.detect {|param| param.name == parameter.name }
        existing.description    = parameter.description unless parameter.from_path?
        existing.param_type     = parameter.param_type if parameter.from_path?
        existing.required     ||= parameter.required
        existing.allow_multiple = parameter.allow_multiple
      elsif parameter.param_type == 'body' && @parameters.detect {|param| param.param_type == 'body'}
        SwaggerYard.log.warn 'multiple body parameters invalid: ' \
          "ignored #{parameter.name} for #{@path_item.api_group.class_name}##{ruby_method}"
      else
        @parameters << parameter
      end
    end

    ##
    # Example:
    # @response_type [Ownership] the requested ownership
    def add_response_type(type, desc)
      @default_response = Response.new.tap do |r|
        r.status = 'default'
        r.type = type
        r.description = desc
      end
    end

    def add_response(tag)
      tag = SwaggerYard.requires_name(tag)
      return unless tag
      @responses << Response.new.tap do |r|
        r.status = Integer(tag.name)
        r.description = tag.text if tag.text
        r.type = Type.from_type_list(Array(tag.types)) if tag.types
      end
    end

    def sort_parameters
      @parameters.sort_by! {|p| p.name}
    end

    private
    def parse_path_params(path)
      path.scan(/\{([^\}]+)\}/).flatten
    end
  end
end
