module SwaggerYard
  class Authorization
    attr_reader :type, :pass_as, :key
    attr_writer :name

    def self.from_yard_object(yard_object)
      text = yard_object.text || ''
      new(yard_object.types.first, yard_object.name, *text.split(' ', 2))
    end

    def initialize(type, pass_as, key = nil, name = nil)
      @type, @pass_as, @key, @name = type, pass_as, key, name
    end

    # the spec suggests most auth names are just the type of auth
    def name
      @name ||= [@pass_as, @key].compact.join('_').downcase.gsub('-', '_')
    end
  end
end
