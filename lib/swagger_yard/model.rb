module SwaggerYard
  #
  # Carries id (the class name) and properties for a referenced
  #   complex model object as defined by swagger schema
  #
  class Model
    include Example
    attr_reader :id, :discriminator, :inherits,
      :description, :properties, :additional_properties

    def self.from_yard_object(yard_object)
      new.tap do |model|
        model.add_info(yard_object)
        model.parse_tags(yard_object.tags)
        yard_object.children.each do |child|
          next unless child.is_a?(YARD::CodeObjects::MethodObject)
          prop = Property.from_method(child)
          model.properties << prop if prop
        end
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

    TAG_ORDER = %w(model inherits discriminator property example additional_properties)

    def parse_tags(tags)
      sorted_tags = tags.each_with_index.sort_by { |t,i|
        [TAG_ORDER.index(t.tag_name) || 0, i] }.map(&:first)
      sorted_tags.each do |tag|
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
          if tag.name && !tag.name.empty?
            if (prop = property(tag.name))
              prop.example = tag.text
            else
              SwaggerYard.log.warn("no property '#{tag.name}' defined yet to which to attach example: #{tag.text.inspect}")
            end
          else
            self.example = tag.text
          end
        when "additional_properties"
          @additional_properties = Type.new(tag.text).schema
        end
      end

      self
    end
  end
end
