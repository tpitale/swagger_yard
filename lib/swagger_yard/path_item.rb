module SwaggerYard
  class PathItem
    attr_accessor :operations, :api_group

    def initialize(api_group = nil)
      @api_group = api_group
      @operations = {}
    end

    def add_operation(yard_object)
      operation = Operation.from_yard_object(yard_object, self)
      @operations[operation.http_method.downcase] = operation
    end

    def +(other)
      PathItem.new(api_group).tap do |pi|
        pi.operations = operations.merge(other.operations)
      end
    end
  end
end
