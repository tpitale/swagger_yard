module SwaggerYard
  module Example
    def example
      @example
    end

    def example=(val)
      @example = begin
        JSON.parse(val)
      rescue
        val
      end
    end
  end
end
