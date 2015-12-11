module YARDHelpers
  def yard_tag(content)
    parser = YARD::DocstringParser.new
    parser.parse content
    parser.tags.first
  end
end
