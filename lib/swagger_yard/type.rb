module SwaggerYard
  class Type
    def self.from_type_list(types)
      parts = types.first.split(/[<>]/)
      args = [parts.last]
      case parts.first
      when /^array$/i
        args << true
      when /^enum$/i
        args = [nil, false, parts.last.split(/[,|]/)]
      end if parts.size > 1
      new(*args)
    end

    attr_reader :name, :array, :enum

    def initialize(name, array = false, enum = nil)
      @name, @array, @enum = name, array, enum
    end

    # TODO: have this look at resource listing?
    def ref?
      /[[:upper:]]/.match(name)
    end

    def model_name
      ref? ? name : nil
    end

    alias :array? :array
    alias :enum? :enum

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
      elsif enum?
        { "type" => "string", "enum" => @enum }
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
