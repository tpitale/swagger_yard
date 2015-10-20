module SwaggerYard
  class Api
    attr_accessor :path, :description, :operations, :api_declaration

    def self.path_from_yard_object(yard_object)
      if tag = yard_object.tags.detect {|t| t.tag_name == "path"}
        tag.text
      else
        nil
      end
    end

    def self.from_yard_object(yard_object, api_declaration)
      path = path_from_yard_object(yard_object)
      description = yard_object.docstring

      new(path, description, api_declaration)
    end

    def initialize(path, description, api_declaration)
      @api_declaration = api_declaration
      @description = description
      @path = path

      @operations = []
    end

    def add_operation(yard_object)
      @operations << Operation.from_yard_object(yard_object, self)
    end

    def to_h
      {
        path => @operations.map(&:to_h)
      }
    end

    def model_names
      @operations.map(&:model_names).flatten.compact.uniq
      # @parameters.select {|p| ref?(p['type'])}.map {|p| p['type']}.uniq
    end

    def ref?(data_type)
      @api_declaration.ref?(data_type)
    end
  end
end
