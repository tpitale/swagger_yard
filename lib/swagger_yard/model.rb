module SwaggerYard
  #
  # Carries id (the class name) and properties for a referenced
  #   complex model object as defined by swagger schema
  #
  class Model
    attr_reader :id, :discriminator, :inherits, :description, :properties, :example

    def self.from_yard_object(yard_object)
      new.tap do |model|
        model.add_info(yard_object)
        model.parse_tags(yard_object.tags)
      end
    end

    def self.mangle(name)
      name.gsub(/[^[:alnum:]_]+/, '_')
    end

    def initialize
      @properties = []
      @inherits = []
    end

    def valid?
      !id.nil? && @has_model_tag
    end

    def add_info(yard_object)
      @description = yard_object.docstring
      @id = Model.mangle(yard_object.path)
    end

    def property(key)
      properties.detect {|prop| prop.name == key }
    end

    def parse_tags(tags)
      tags.each do |tag|
        case tag.tag_name
        when "model"
          @has_model_tag = true
          @id = Model.mangle(tag.text) unless tag.text.empty?
        when "property"
          prop = Property.from_tag(tag)
          @properties << prop if prop
        when "discriminator"
          prop = Property.from_tag(tag)
          if prop
            @properties << prop
            @discriminator ||= prop.name
          end
        when "inherits"
          @inherits << tag.text
        when "example"
          value = JSON.parse(tag.text) rescue tag.text
          if tag.name && !tag.name.empty?
            if (prop = property(tag.name))
              prop.example = value
            else
              SwaggerYard.log.warn("no property '#{tag.name}' defined yet to which to attach example: #{value.inspect}")
            end
          else
            @example = value
          end
        end
      end

      self
    end
  end
end
