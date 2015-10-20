module SwaggerYard
  class Type
    def self.from_type_list(types)
      parts = types.first.split(/[<>]/)
      new(parts.last, parts.grep(/array/i).any?)
    end

    attr_reader :name, :array

    def initialize(name, array=false)
      @name, @array = name, array
    end

    # TODO: have this look at resource listing?
    def ref?
      /[[:upper:]]/.match(name)
    end

    def model_name
      ref? ? name : nil
    end

    alias :array? :array

    def json_type
      type, format = name, nil
      case name
      when "float", "double"
        type = "number"
        format = name
      when "date-time", "date", "time"
        type = "string"
        format = name
      end
      {}.tap do |h|
        h["type"]   = type
        h["format"] = format if format
      end
    end

    def to_h
      type = if ref?
        { "$ref" => "#/definitions/#{name}"}
      else
        json_type
      end
      if array?
        { "type" => "array", "items" => type }
      else
        type
      end
    end
  end
end
