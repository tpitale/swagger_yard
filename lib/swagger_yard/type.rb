module SwaggerYard
  class Type
    def self.from_type_list(types)
      new(types.first)
    end

    attr_reader :name, :source, :schema

    def initialize(string)
      @source  = string
      @schema  = TypeParser.new.json_schema(string)
      @name    = name_for(@schema)
      @name    = name_for(@schema['items']) if @name == 'array'
    end

    # TODO: have this look at resource listing?
    def ref?
      schema["$ref"]
    end

    def model_name
      ref? ? name : nil
    end

    def to_h
      schema
    end

    private
    def name_for(schema)
      schema["type"] || schema["$ref"][%r'#/definitions/(.*)', 1]
    end
  end
end
