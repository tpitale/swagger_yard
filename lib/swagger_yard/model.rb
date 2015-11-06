module SwaggerYard
  #
  # Carries id (the class name) and properties for a referenced
  #   complex model object as defined by swagger schema
  #
  class Model
    attr_reader :id

    def self.from_yard_object(yard_object)
      new.tap do |model|
        model.parse_tags(yard_object.tags)
      end
    end

    def initialize
      @properties = []
    end

    def valid?
      !id.nil?
    end

    def parse_tags(tags)
      tags.each do |tag|
        case tag.tag_name
        when "model"
          @id = tag.text
        when "property"
          @properties << Property.from_tag(tag)
        end
      end

      self
    end

    def to_h
      {}.tap do |h|
        h["properties"] = Hash[@properties.map {|p| [p.name, p.to_h]}]
        h["required"] = @properties.select(&:required?).map(&:name) if @properties.detect(&:required?)
      end
    end
  end
end
