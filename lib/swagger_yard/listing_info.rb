module SwaggerYard
  class ListingInfo
    attr_reader :description, :resource, :resource_path, :authorizations

    def initialize(yard_object)
      @description = yard_object.docstring

      if tag = yard_object.tags.detect {|t| t.tag_name == "resource"}
        @resource = tag.text
      end

      if tag = yard_object.tags.detect {|t| t.tag_name == "resource_path"}
        @resource_path = tag.text.downcase
      end

      @authorizations = yard_object.tags.select {|t| t.tag_name == "authorize_with"}.map(&:text)
    end
  end
end
