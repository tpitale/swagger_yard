module SwaggerYard
  #
  # Holds the name and type for a single model property
  #
  class Property
    include Example
    attr_reader :name, :description, :required, :type, :nullable

    def self.from_tag(tag)
      tag = SwaggerYard.requires_name_and_type(tag)
      return nil unless tag

      name, options_string = tag.name.split(/[\(\)]/)

      options = options_string.to_s.split(',').map(&:strip)

      new(name, tag.types, tag.text, options)
    end

    def initialize(name, types, description, options)
      @name, @description = name, description
      @required = options.include?('required')
      @nullable = options.include?('nullable')
      @type = Type.from_type_list(types)
    end

     def required?
      @required
    end
  end
end
