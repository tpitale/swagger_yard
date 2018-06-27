require "yard"
require "json"
require "swagger_yard/configuration"
require "swagger_yard/type"
require "swagger_yard/type_parser"
require "swagger_yard/parameter"
require "swagger_yard/property"
require "swagger_yard/operation"
require "swagger_yard/authorization"
require "swagger_yard/specification"
require "swagger_yard/api_group"
require "swagger_yard/model"
require "swagger_yard/path_item"
require "swagger_yard/swagger"
require "swagger_yard/openapi"

module SwaggerYard
  class Error < StandardError; end
  class InvalidTypeError < Error; end
  class UndefinedSchemaError < Error; end

  class << self
    ##
    # Configuration for Swagger Yard, use like:
    #
    #   SwaggerYard.configure do |config|
    #     config.swagger_version = "1.1"
    #     config.api_version = "0.1"
    #     config.doc_base_path = "http://swagger.example.com/doc"
    #     config.api_base_path = "http://swagger.example.com/api"
    #     config.reload = true # Rails.env.development?
    #   end
    def configure
      yield config
    end

    def config
      @configuration ||= Configuration.new
    end

    def log
      YARD::Logger.instance
    end

    # Validates that the tag has non-nil values for the given attribute methods.
    # Logs a warning message and returns nil if the tag is not valid.
    def requires_attrs(tag, *attrs)
      valid = true
      attrs.each do |a|
        valid &&= tag.send(a)
        break unless valid
      end
      unless valid
        if tag.object
          object   = " in #{tag.object.to_s}"
          location = " near #{tag.object.files.first.join(':')}" if tag.object.files.first
        end
        log.warn "invalid @#{tag.tag_name} tag#{object}#{location}"
        return nil
      end
      tag
    end

    def requires_name(tag)
      requires_attrs(tag, :name)
    end

    def requires_name_and_type(tag)
      requires_attrs(tag, :name, :types)
    end

    def requires_type(tag)
      requires_attrs(tag, :types)
    end

    #
    # Use YARD to parse object tags from a file
    #
    # @param file_path [string] The complete path to file
    # @param types additional types by which to filter the result (:class/:module/:method)
    # @return [YARD] objects representing class/methods and tags from the file
    #
    def yard_objects_from_file(file_path, *types)
      ::YARD.parse(file_path)
      ::YARD::Registry.all(*types).select {|co| co.file == file_path }
    end

    #
    # Parse all objects in the file and return the class objects found.
    #
    # @param file_path [string] The complete path to file
    # @return [YARD] objects representing classes from the file
    #
    def yard_class_objects_from_file(file_path)
      yard_objects_from_file(file_path, :class)
    end

    ##
    # Register some custom yard tags used by swagger-ui
    def register_custom_yard_tags!
      ::YARD::Tags::Library.define_tag("Api resource", :resource)
      ::YARD::Tags::Library.define_tag("Api path", :path, :with_types)
      ::YARD::Tags::Library.define_tag("Parameter", :parameter, :with_types_name_and_default)
      ::YARD::Tags::Library.define_tag("Response type", :response_type, :with_types)
      ::YARD::Tags::Library.define_tag("Error response message", :error_message, :with_types_and_name)
      ::YARD::Tags::Library.define_tag("Response", :response, :with_types_and_name)
      ::YARD::Tags::Library.define_tag("Api Summary", :summary)
      ::YARD::Tags::Library.define_tag("Model resource", :model)
      ::YARD::Tags::Library.define_tag("Model superclass", :inherits)
      ::YARD::Tags::Library.define_tag("Model property", :property, :with_types_name_and_default)
      ::YARD::Tags::Library.define_tag("Model discriminator", :discriminator, :with_types_name_and_default)
      ::YARD::Tags::Library.define_tag("Authorization", :authorization, :with_types_and_name)
      ::YARD::Tags::Library.define_tag("Authorization Use", :authorize_with)
    end
  end
end
