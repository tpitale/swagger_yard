module SwaggerYard
  class Type
    def self.from_type_list(types)
      new(types.first)
    end

    MODEL_PATH = '#/definitions/'.freeze

    attr_reader :name, :source, :schema

    def initialize(string)
      @source  = string
      @schema  = TypeParser.new.json_schema(string)
      @name    = name_for(@schema)
      @name    = name_for(@schema['items']) if @name == 'array'
    end

    def ref?
      schema["$ref"]
    end

    def model_name
      ref? ? name : nil
    end

    def schema_with(model_path: MODEL_PATH)
      if ref? && model_path != MODEL_PATH
        { '$ref' => schema[$ref].sub(MODEL_PATH, model_path) }
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
