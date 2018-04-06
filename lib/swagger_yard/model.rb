module SwaggerYard
  #
  # Carries id (the class name) and properties for a referenced
  #   complex model object as defined by swagger schema
  #
  class Model
    attr_reader :id, :discriminator, :inherits, :description

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
      !id.nil?
    end

    def add_info(yard_object)
      @description = yard_object.docstring
      @id = Model.mangle(yard_object.path)
    end

    def parse_tags(tags)
      tags.each do |tag|
        case tag.tag_name
        when "model"
          @id = Model.mangle(tag.text) unless tag.text.empty?
        when "property"
          @properties << Property.from_tag(tag)
        when "discriminator"
          prop = Property.from_tag(tag)
          @properties << prop
          @discriminator ||= prop.name
        when "inherits"
          @inherits << tag.text
        end
      end

      self
    end

    def inherits_references
      @inherits.map { |name| Type.new(name).to_h }
    end

    def to_h
      h = {
        "type" => "object",
        "properties" => Hash[@properties.map {|p| [p.name, p.to_h]}]
      }

      h["required"] = @properties.select(&:required?).map(&:name) if @properties.detect(&:required?)
      h["discriminator"] = @discriminator if @discriminator

      # Polymorphism
      h = { "allOf" => inherits_references + [h] } unless @inherits.empty?

      # Description
      h["description"] = @description unless @description.empty?

      h
    end
  end
end
