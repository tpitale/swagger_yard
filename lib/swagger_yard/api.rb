module SwaggerYard
  class Api
    attr_accessor :path, :operations, :api_declaration

    def self.path_from_yard_object(yard_object)
      if tag = yard_object.tags.detect {|t| t.tag_name == "path"}
        tag.text
      elsif fn = SwaggerYard.config.path_discovery_function
        begin
          method, path = fn[yard_object]
          yard_object.add_tag YARD::Tags::Tag.new("path", path, [method]) if path
          path
        rescue => e
          YARD::Logger.instance.warn e.message
          nil
        end
      end
    end

    def self.from_yard_object(yard_object, api_declaration)
      path = path_from_yard_object(yard_object)
      new(path, api_declaration)
    end

    def initialize(path, api_declaration)
      @api_declaration = api_declaration
      @path = path
      @operations = []
    end

    def add_operation(yard_object)
      @operations << Operation.from_yard_object(yard_object, self)
    end

    def operations_hash
      Hash[@operations.map {|op| [op.http_method.downcase, op.to_h]}]
    end
  end
end
