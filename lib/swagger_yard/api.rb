module SwaggerYard
  class Api
    attr_accessor :path, :description, :operations, :api_declaration

    def self.path_from_yard_object(yard_object)
      if tag = yard_object.tags.detect {|t| t.tag_name == "path"}
        tag.text
      elsif fn = SwaggerYard.config.path_discovery_function
        fn[yard_object]
      end
    end

    def self.from_yard_object(yard_object, api_declaration)
      path = path_from_yard_object(yard_object)
      description = yard_object.docstring

      new(path, description, api_declaration)
    end

    def initialize(path, description, api_declaration)
      @api_declaration = api_declaration
      @description = description
      @path = path

      @operations = []
    end

    def add_operation(yard_object)
      @operations << Operation.from_yard_object(yard_object, self)
    end

    def model_names
      @operations.map(&:model_names).flatten.compact.uniq
    end

    def ref?(data_type)
      @api_declaration.ref?(data_type)
    end

    def operations_hash
      Hash[@operations.map {|op| [op.http_method.downcase, op.to_h]}]
    end
  end
end
