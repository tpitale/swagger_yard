module SwaggerYard::Directives
  
  # A directive used to create a model tag with a dummy class.
  # based on https://github.com/lsegal/yard/blob/master/lib/yard/tags/directives.rb#L361
  class ParamClassDirective < YARD::Tags::Directive

    def call; end

    def after_parse
      return unless handler

      create_object
    end

    def create_object
      name = tag.name
      obj = YARD::CodeObjects::ClassObject.new(handler.namespace, tag.name)
      handler.register_file_info(obj)
      handler.register_source(obj)
      handler.register_group(obj)
      obj.docstring = YARD::Docstring.new!(parser.text,
                                           parser.tags,
                                           obj,
                                           nil,
                                           parser.reference)
      obj.add_tag(YARD::Tags::Tag.new(:model, name))
      parser.object = obj
      parser.post_process
      obj
    end
  end
end
