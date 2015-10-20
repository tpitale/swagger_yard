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

    def to_h
      type_tag = ref? ? "$ref" : "type"
      if array?
        {"type"=>"array", "items"=> { type_tag => name }}
      else
        {"type"=>name}
      end
    end

    def swagger_v2
      type = if ref?
        { "$ref" => "#/definitions/#{name}"}
      else
        { "type" => name }
      end
      if array?
        { "type" => "array", "items" => type }
      else
        type
      end
    end
  end
end
