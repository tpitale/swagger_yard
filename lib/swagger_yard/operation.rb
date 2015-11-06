module SwaggerYard
  class Operation
    attr_accessor :description, :ruby_method
    attr_writer :summary
    attr_reader :path, :http_method, :error_messages, :response_type, :response_desc
    attr_reader :parameters, :model_names

    # TODO: extract to operation builder?
    def self.from_yard_object(yard_object, api)
      new(api).tap do |operation|
        operation.ruby_method = yard_object.name(false)
        operation.description = yard_object.docstring
        yard_object.tags.each do |tag|
          case tag.tag_name
          when "path"
            operation.add_path_params_and_method(tag)
          when "parameter"
            operation.add_parameter(tag)
          when "response_type"
            operation.add_response_type(Type.from_type_list(tag.types), tag.text)
          when "error_message"
            operation.add_error_message(tag)
          when "summary"
            operation.summary = tag.text
          end
        end

        operation.sort_parameters
      end
    end

    def initialize(api)
      @api            = api
      @summary        = nil
      @description    = ""
      @parameters     = []
      @model_names    = []
      @error_messages = []
    end

    def summary
      @summary || description.split("\n\n").first || ""
    end

    def to_h
      params      = parameters.map(&:to_h)
      responses   = { "default" => { "description" => response_desc || summary } }

      if response_type
        responses["default"]["schema"] = response_type.to_h
      end

      unless error_messages.empty?
        error_messages.each do |err|
          responses[err["code"].to_s] = {}.tap do |h|
            h["description"] = err["message"]
            h["schema"] = Type.from_type_list(Array(err["responseModel"])).to_h if err["responseModel"]
          end
        end
      end

      {
        "tags"        => [@api.api_declaration.resource].compact,
        "operationId" => "#{@api.api_declaration.resource}-#{ruby_method}",
        "parameters"  => params,
        "responses"   => responses,
      }.tap do |h|
        h["description"] = description unless description.empty?
        h["summary"]     = summary unless summary.empty?

        authorizations = @api.api_declaration.authorizations
        unless authorizations.empty?
          h["security"] = authorizations.map {|k,v| { k => v} }
        end
      end
    end

    ##
    # Example: [GET] /api/v2/ownerships
    # Example: [PUT] /api/v1/accounts/{account_id}
    def add_path_params_and_method(tag)
      @path = tag.text
      @http_method = tag.types.first

      parse_path_params(tag.text).each do |name|
        @parameters << Parameter.from_path_param(name)
      end
    end

    ##
    # Example: [Array]     status            Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Array]     status(required)  Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Array]     status(required, body)  Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Integer]   media[media_type_id]                          ID of the desired media type.
    def add_parameter(tag)
      @parameters << Parameter.from_yard_tag(tag, self)
    end

    ##
    # Example:
    # @response_type [Ownership] the requested ownership
    def add_response_type(type, desc)
      model_names << type.model_name
      @response_type = type
      @response_desc = desc
    end

    def add_error_message(tag)
      @error_messages << {
        "code" => Integer(tag.name),
        "message" => tag.text,
        "responseModel" => Array(tag.types).first
      }.reject {|_,v| v.nil?}
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
