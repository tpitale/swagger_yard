module SwaggerYard
  #
  # Holds the name and type for a single model property
  #
  class Property
    include Example
    attr_reader :name, :required, :type, :nullable
    attr_accessor :description

    NAME_OPTIONS_REGEXP = /[()]/

    def self.tag_name(tag)
      if tag.object.is_a?(YARD::CodeObjects::MethodObject)
        tag.object.name.to_s
      else
        tag = SwaggerYard.requires_name(tag)
        return nil unless tag
        tag.name.split(NAME_OPTIONS_REGEXP).first
      end
    end

    def self.from_method(yard_method)
      return nil unless yard_method.explicit || yard_method.parameters.empty?
      tags = (yard_method.tags || []).dup
      prop_tag = tags.detect { |t| t.tag_name == "property" }
      return nil unless prop_tag
      tags.reject { |t| t.tag_name == "property" }
      from_tag(prop_tag).tap do |prop|
        ex = tags.detect { |t| t.tag_name == "example" }
        prop.example = ex.text.empty? ? ex.name : ex.text if ex
        prop.description = yard_method.docstring unless prop.description
      end
    end

    def self.from_tag(tag)
      tag = SwaggerYard.requires_type(tag)
      return nil unless tag

      name = tag_name(tag)
      return nil unless name

      text = tag.text

      if NAME_OPTIONS_REGEXP.match?((options_src = (tag.name || "")))
        _, options_string = options_src.split(NAME_OPTIONS_REGEXP)
      elsif tag.name && tag.object.is_a?(YARD::CodeObjects::MethodObject)
        text = if text
          tag.name + " " + text
        else
          tag.name
        end
      end

      options = options_string.to_s.split(",").map(&:strip)

      new(name, tag.types, text, options)
    end

    def initialize(name, types, description, options)
      @name, @description = name, description
      @required = options.include?("required")
      @nullable = options.include?("nullable")
      @type = Type.from_type_list(types)
    end

    def required?
      @required
    end
  end
end
