module SwaggerYard
  class Authorization
    attr_reader :type, :name, :description
    attr_writer :id, :key

    def self.from_yard_object(yard_object)
      new(yard_object.types.first, yard_object.name, yard_object.text)
    end

    def initialize(type, name, description)
      @type, @name, @description = type, name, description
      @key = nil
    end

    def key
      return @key if @key
      return nil unless @description
      return nil unless @type =~ /api_?key|bearer/i
      @key, @description = @description.split(' ', 2)
      @key
    end

    def id
      @id ||= api_key_id || name
    end

    private
    def api_key_id
      case type
      when /api_?key/i
        [name, key].compact.join('_').downcase.gsub('-', '_')
      else
        nil
      end
    end
  end
end
