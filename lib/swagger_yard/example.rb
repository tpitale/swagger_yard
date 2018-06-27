module SwaggerYard
  module Example
    def example
      @example
    end

    def example=(val)
      @example = JSON.parse(val) rescue val
    end
  end
end
