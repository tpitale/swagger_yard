module SwaggerYard
  class Type
    def self.from_type_list(types)
      parts = types.first.split(/[<>]/)
      name = parts.last
      options = {}
      if parts.size > 1
        case parts.first
        when /^array$/i
          options[:array] = true
        when /^enum$/i
          name = nil
          options[:enum] = parts.last.split(/[,|]/)
        when /^regexp?$/i
          name = 'string'
          options[:pattern] = parts.last
        when /^object$/i
          options[:object] = parts[1..-1]
        else
          name = parts.first
          options[:format] = parts.last
        end
      end
      new(name, options)
    end

    attr_reader :name, :array, :enum, :object

    def initialize(name, options = {})
      @name    = Model.mangle(name) if name
      @array   = options[:array]
      @enum    = options[:enum]
      @format  = options[:format]
      @pattern = options[:pattern]
      @object  = options[:object]
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
    alias :object? :object

    def json_type
      type, format = name, @format
      case name
      when "float", "double"
        type = "number"
        format = name
      when "date-time", "date", "time", "uuid"
        type = "string"
        format = name
      end

      hsh = { "type" => type }
      hsh["format"] = format if format
      hsh["pattern"] = @pattern if @pattern
      hsh
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
      elsif object?
        {
          "type" => "object",
          "additionalProperties" => Type.from_type_list([object.join("<")]).to_h
        }
      else
        type
      end
    end
  end
end
