module SwaggerYard
  #
  # Carries id (the class name) and properties for a referenced
  #   complex model object as defined by swagger schema
  #
  Model = Struct.new(:id, :discriminator, :inherits, :description, :properties, :additional_properties, :example, keyword_init: true) do
    def property(key)
      properties.detect { |prop| prop.name == key }
    end
  end

  class ModelParser
    def model
      return unless id

      Model.new(
        id: id,
        discriminator: discriminator,
        inherits: inherits,
        description: @yard_object.docstring,
        properties: properties,
        example: example,
        additional_properties: additional_properties,
      )
    end

    def self.from_yard_object(yard_object)
      new(yard_object).model
    end

    def self.mangle(name)
      name.gsub(/[^[:alnum:]_]+/, '_')
    end

    def initialize(yard_object)
      @yard_object = yard_object
    end

    def id
      return unless tag('model')

      name = tag('model').text.presence || @yard_object.path

      self.class.mangle(name)
    end

    def inherits
      tags('inherits').map(&:text)
    end

    def discriminator
      return unless tag('discriminator')

      Property.from_tag(tag('discriminator')).name
    end

    def properties
      return @properties if @properties

      @properties = []

      # Properties from the direct tags
      tags('property').each do |property_tag|
        property = Property.from_tag(property_tag)
        @properties.push property if property
      end

      # Property from discriminator tag
      @properties.push Property.from_tag(tag('discriminator')) if tag('discriminator')

      # Properties from nested method definition
      @yard_object.children.each do |child|
        next unless child.is_a?(YARD::CodeObjects::MethodObject)
        property = Property.from_method(child)
        @properties.push property if property
      end

      # Search examples
      tags('example').each do |example_tag|
        next if example_tag.name.blank?

        property = @properties.find { |prop| prop.name == example_tag.name }
        if property
          property.example = example_tag.text
        else
          SwaggerYard.log.warn <<~MESSAGE
            no property '#{example_tag.name}' defined yet to which to attach example:

              #{example_tag.text.inspect}

          MESSAGE
        end
      end

      @properties
    end

    def tag(key)
      @yard_object.tags.find { |tag| tag.tag_name == key }
    end

    def tags(key)
      @yard_object.tags.select { |tag| tag.tag_name == key }
    end

    def additional_properties
      return unless tag('additional_properties')

      Type.new(tag('additional_properties').text).schema
    end

    def example
      tag = tags('example').find { |tag| tag.name.blank? }
      return unless tag

      JSON.parse(tag.text) rescue tag.text
    end
  end
end
