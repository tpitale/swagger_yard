module SwaggerYard
  class Api
    attr_reader :nickname
    attr_accessor :path, :parameters, :description, :http_method, :response_class, :summary, :notes, :error_responses

    def initialize(resource_listing, yard_object)
      @resource_listing = resource_listing

      @description = yard_object.docstring
      @parameters  = []
      
      yard_object.tags.each do |tag|
        value = tag.text

        case tag.tag_name
        when "path"
          parse_path(value)
        when "parameter"
          @parameters << parse_parameter(tag)
        when "parameter_list"
          @parameters << parse_parameter_list(value)
        when "summary"
          @summary = value
        when "notes"
          @notes = value.gsub("\n", "<br\>")
        end
      end

      @parameters.sort_by { |parameter| parameter["name"] }
      @parameters << add_format_parameters
    end

    def nickname
      @nickname ||= "#{http_method}".camelize
    end

    def operation 
      {
        "httpMethod"     => http_method,
        "nickname"       => path[1..-1].gsub(/[^a-zA-Z\d:]/, '-').squeeze("-") + http_method.downcase,
        "responseClass"  => response_class || "void",
        "produces"       => ["application/json", "application/xml"],
        "parameters"     => parameters,
        "summary"        => summary || description,
        "notes"          => notes,
        "errorResponses" => error_responses
      }
    end

    def to_h
      {
        "path"        => path,
        "description" => description,
        "operations"  => [operation],
      }
    end

    def model_names
      @parameters.select {|p| ref?(p['type'])}.map {|p| p['type']}.uniq
    end

    def valid?
      path.present?
    end

    def ref?(data_type)
      @resource_listing.models.map(&:id).include?(data_type)
    end

  private
    ##
    # Example: [GET] /api/v2/ownerships.{format_type}
    def parse_path(string)
      # TODO: switch to :with_types_and_title on tag parsing
      @http_method, @path = string.match(/^\[(\w*)\]\s*(.*)$/).captures

      path_params = @path.scan(/\{([^\}]+)\}/).flatten.reject { |value| value == "format_type" }
      
      path_params.each do |path_param|
        @parameters << {
          "paramType"     => "path",
          "name"          => path_param,
          "description"   => "Scope response to #{path_param}",
          "type"          => "string",
          "required"      => true,
          "allowMultiple" => false
        }
      end
    end

    ##
    # Example: [Array]     status            Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Array]     status(required)  Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Array]     status(required, body)  Filter by status. (e.g. status[]=1&status[]=2&status[]=3)
    # Example: [Integer]   media[media_type_id]                          ID of the desired media type.
    def parse_parameter(tag)
      Parameter.from_yard_tag(self, tag).to_h
    end

    ##
    # Example: [String]    sort_order  Orders ownerships by fields. (e.g. sort_order=created_at)
    #          [List]      id              
    #          [List]      begin_at        
    #          [List]      end_at          
    #          [List]      created_at      
    def parse_parameter_list(string)
      data_type, name, required, description, set_string = string.match(/\A\[(\w*)\]\s*(\w*)(\(required\))?\s*(.*)\n([.\s\S]*)\Z/).captures
      
      list_values = set_string.split("[List]").map(&:strip).reject { |string| string.empty? }

      parameter = {
        "paramType"       => "query",
        "name"            => name,
        "description"     => description,
        "type"            => data_type.downcase,
        "required"        => required.present?,
        "allowMultiple"   => false,
        "allowableValues" => {"valueType" => 'LIST', "values" => list_values}
      }
    end

    def add_format_parameters
      {
        "paramType"       => "path",
        "name"            => "format_type",
        "description"     => "Response format either JSON or XML",
        "type"            => "string",
        "required"        => true,
        "allowMultiple"   => false,
        "allowableValues" => {"valueType" => "LIST", "values" => ["json", "xml"]}
      }
    end
  end
end