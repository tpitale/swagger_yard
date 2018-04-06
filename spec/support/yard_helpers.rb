module YARDHelpers
  def yard_tag(content)
    parser = YARD::DocstringParser.new
    parser.parse content
    parser.tags.first
  end

  def yard_method(name, content)
    method = YARD::CodeObjects::MethodObject.new(nil, name)
    method.docstring = YARD::Docstring.new(content, method)
    method
  end

  def yard_class(name, content)
    klass = YARD::CodeObjects::ClassObject.new(nil, name)
    klass.docstring = YARD::Docstring.new(content, klass)
    klass
  end
end
