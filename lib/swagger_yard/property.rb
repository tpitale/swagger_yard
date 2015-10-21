module SwaggerYard
  #
  # Holds the name and type for a single model property
  #
  class Property
    attr_reader :name, :description

    def self.from_tag(tag)
      name, options_string = tag.name.split(/[\(\)]/)

      required = options_string.to_s.split(',').map(&:strip).include?('required')

      new(name, tag.types, tag.text, required)
    end

    def initialize(name, types, description, required)
      @name, @description, @required = name, description, required

      @type = Type.from_type_list(types)
    end

    def required?
      @required
    end

    def model_name
      @type.model_name
    end

    def to_h
      @type.to_h.tap do |h|
        h["description"] = description if description
      end
    end
  end
end
