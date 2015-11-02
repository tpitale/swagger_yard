module SwaggerYard
  class Operation
    attr_accessor :description, :summary, :ruby_method
    attr_reader :path, :http_method, :error_messages, :response_type, :response_desc
    attr_reader :parameters, :model_names

    PARAMETER_LIST_REGEX = /\A\[(\w*)\]\s*(\w*)(\(required\))?\s*(.*)\n([.\s\S]*)\Z/

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
          when "parameter_list"
            operation.add_parameter_list(tag)
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
      @api = api
      @description = ""
      @parameters = []
      @model_names = []
      @error_messages = []
    end

    def nickname
      @path[1..-1].gsub(/[^a-zA-Z\d:]/, '-').squeeze("-") + http_method.downcase
    end

    def summary
      @summary || description.split("\n\n").first
    end

    def to_h
      method      = http_method.downcase
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
    # Example: [String]    sort_order  Orders ownerships by fields. (e.g. sort_order=created_at)
    #          [List]      id              
    #          [List]      begin_at        
    #          [List]      end_at          
    #          [List]      created_at      
    def add_parameter_list(tag)
      # TODO: switch to using Parameter.from_yard_tag
      data_type, name, required, description, list_string = parse_parameter_list(tag)
      allowable_values = parse_list_values(list_string)

      @parameters << Parameter.new(name, Type.new(data_type.downcase), description, {
        required: !!required,
        param_type: "query",
        allow_multiple: false,
        allowable_values: allowable_values
      })
    end

    ##
    # Exaample:
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

    def ref?(data_type)
      @api.ref?(data_type)
    end

    private
    def parse_path_params(path)
      path.scan(/\{([^\}]+)\}/).flatten
    end

    def parse_parameter_list(tag)
      tag.text.match(PARAMETER_LIST_REGEX).captures
    end

    def parse_list_values(list_string)
      list_string.split("[List]").map(&:strip).reject { |string| string.empty? }
    end
  end
end
