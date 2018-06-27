module SwaggerYard
  class Type
    def self.from_type_list(types)
      new(types.first)
    end

    # Default model location path
    MODEL_PATH = '#/definitions/'.freeze

    attr_reader :source

    def initialize(string)
      @source  = string
      @name    = nil
    end

    def name
      return @name if @name
      @name = name_for(schema)
      @name = name_for(schema['items']) if @name == 'array'
      @name
    end

    def ref?
      schema["$ref"]
    end

    def schema
      @schema ||= TypeParser.new.json_schema(source)
    end

    def schema_with(options = {})
      model_path = options && options[:model_path] || MODEL_PATH
      if model_path != MODEL_PATH
        TypeParser.new(model_path).json_schema(source)
      else
        schema
      end
    end

    private
    def name_for(schema)
      schema["type"] || schema["$ref"][%r'.*/([^/]*)$', 1]
    end
  end
end
