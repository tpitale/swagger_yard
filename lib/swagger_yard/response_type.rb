module SwaggerYard
  #
  # Holds the name and type for a single model property
  #
  class ResponseType
    attr_reader :name

    def self.from_tag(tag)
      new(tag.types, tag.text)
    end

    def initialize(types, description)
      @types, @description = types, description
    end

    def type
      is_array? ? @types[1] : @types[0]
    end

    def is_array?
      @types[0] == "array"
    end

    def is_ref?
      /[[:upper:]]/.match(type[0])
    end

    def to_h
      type_tag = is_ref? ? "$ref" : "type"
      result = if is_array?
        { "type" => "array", "items" => { type_tag => type } }
      else
        { "type" => type }
      end
    end
  end
end
