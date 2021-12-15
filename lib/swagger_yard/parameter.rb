module SwaggerYard
  class Parameter
    attr_accessor :name, :type, :description, :param_type, :required, :allow_multiple, :example

    def self.from_yard_tag(tag)
      tag = SwaggerYard.requires_name_and_type(tag)
      return nil unless tag

      name, options_string = tag.name.split(/[\(\)]/)
      description, example = tag.text.to_s.split(/\s*--\s*/)
      description = name if description.nil? || description.strip.empty?
      example = nil if !example.nil? && example.strip.empty?
      type = Type.from_type_list(tag.types)

      options = {}

      unless options_string.nil?
        options_string.split(',').map(&:strip).tap do |arr|
          options[:required] = !arr.delete('required').nil?
          options[:allow_multiple] = !arr.delete('multiple').nil?
          options[:param_type] = arr.last
        end
      end

      new(name, type, description, example, options)
    end

    # TODO: support more variation in scope types
    def self.from_path_param(name)
      new(name, Type.new("string"), "Scope response to #{name}", nil, {
        required: true,
        allow_multiple: false,
        param_type: "path",
        from_path: true
      })
    end

    def initialize(name, type, description, example, options={})
      @name, @type, @description, @example = name, type, description, example

      @required = options[:required] || false
      @param_type = options[:param_type] || 'query'
      @allow_multiple = options[:allow_multiple] || false
      @from_path      = options[:from_path] || false
    end

    def from_path?
      @from_path
    end
  end
end
