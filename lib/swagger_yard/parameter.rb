module SwaggerYard
  class Parameter
    attr_accessor :name, :data_type, :description
    attr_reader :param_type, :required, :allow_multiple, :allowable_values

    REGEX = /\A\[(\w*)\]\s*([\w\[\]]*)(\(.*\))?\s*(.*)\Z/

    def self.from_yard_tag(api, tag)
      options = {}
      string = tag.text

      data_type, name, options_string, description = string.match(REGEX).captures
      options[:allow_multiple] = name.gsub!("[]", "") # HUH?

      # TODO: is a method on api
      data_type.downcase! unless api.ref?(data_type)

      unless options_string.nil?
        options_string[1..-2].split(',').map(&:strip).tap do |arr|
          options[:required] = !arr.delete('required').nil?
          options[:param_type] = arr.last
        end
      end

      new(name, data_type, description, options)
    end

    def initialize(name, data_type, description, options={})
      @name, @data_type, @description = name, data_type, description

      @required = options.fetch(:required, false)
      @param_type = options.fetch(:param_type, 'query')
      @allow_multiple = options.fetch(:allow_multiple, false)
    end

    def to_h
      {
        "paramType"     => param_type,
        "name"          => name,
        "description"   => description,
        "required"      => required,
        "type"          => data_type,
        "allowMultiple" => allow_multiple.present?
      }
    end
  end
end