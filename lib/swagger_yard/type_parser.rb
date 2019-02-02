require 'parslet'

module SwaggerYard
  class TypeParser
    class Parser < Parslet::Parser
      # Allow for whitespace surrounding a string value
      def spaced(arg)
        space >> str(arg) >> space
      end

      def stri(str)
        key_chars = str.split(//)
        key_chars.collect! { |char| match["#{char.upcase}#{char.downcase}"] }.
          reduce(:>>)
      end

      rule(:space)      { match[" \n"].repeat }

      rule(:id_char)    { match['-a-zA-Z0-9_'].repeat }

      rule(:id_start)   { match('[a-zA-Z_]') }

      rule(:name)       { id_start >> id_char }

      rule(:identifier) { name >> (str('::') >> name).repeat }

      rule(:external_identifier) { name.as(:namespace) >> str('#') >> identifier.as(:identifier) }

      rule(:regexp)     { stri('regex') >> match['Pp'].maybe >> space >>
                          str('<') >> (str('\\\\') | str('\\>') | match['[^>]']).repeat.as(:regexp) >> str('>') }

      rule(:enum_list)  { name.as(:value) >> (spaced(',') >> name.as(:value)).repeat }

      rule(:enum)       { stri('enum') >> spaced('<') >> enum_list >> spaced('>') }

      rule(:array)      { stri('array') >> spaced('<') >> type >> spaced('>') }

      rule(:pair)       { (name.as(:property) >> spaced(':') >> type.as(:type)).as(:pair) }

      rule(:pairs)      { pair >> (spaced(',') >> pair).repeat >> (spaced(',') >> type.as(:additional)).maybe }

      rule(:object)     { stri('object') >> spaced('<') >> (pairs | type.as(:additional)) >> spaced('>') }

      rule(:formatted)  { name.as(:name) >> spaced('<') >> name.as(:format) >> spaced('>') }

      rule(:type)       { enum.as(:enum) |
                          array.as(:array) |
                          object.as(:object) |
                          formatted.as(:formatted) |
                          external_identifier.as(:external_identifier) |
                          identifier.as(:identifier) |
                          regexp }

      root :type
    end

    class Transform < Parslet::Transform
      rule(identifier: simple(:id)) do
        v = id.to_s
        case v
        when /^array$/i
          { 'type' => 'array', 'items' => { 'type' => 'string' } }
        when /^object$/i
          { 'type' => 'object' }
        when "float", "double"
          { 'type' => 'number', 'format' => v }
        when "date-time", "date", "time", "uuid"
          { 'type' => 'string', 'format' => v }
        else
          name = Model.mangle(v)
          if /[[:upper:]]/.match(name)
            { '$ref' => "#{model_path}#{name}" }
          else
            { 'type' => name }
          end
        end
      end

      rule(external_identifier: { namespace: simple(:namespace), identifier: simple(:identifier) }) do
        prefix, name = namespace.to_s, identifier.to_s
        unless url = SwaggerYard.config.external_schema[prefix]
          raise UndefinedSchemaError, "unknown prefix #{prefix} for #{name}"
        end
        uri = URI(url)
        fragment = uri.fragment ? "##{uri.fragment}" : model_path
        uri.fragment = nil
        fragment += '/' unless fragment.end_with?('/')
        url = uri.to_s
        { '$ref' => "#{url}#{fragment}#{Model.mangle(name)}"}
      end

      rule(formatted: { name: simple(:name), format: simple(:format) }) do
        { 'type' => name.to_s, 'format' => format.to_s }
      end

      rule(regexp: simple(:pattern)) do
        { 'type' => 'string', 'pattern' => pattern.to_s.gsub('\\\\', '\\').gsub('\>', '>') }
      end

      rule(value: simple(:value)) { value.to_s }

      rule(enum: subtree(:values)) do
        { 'type' => 'string', 'enum' => Array(values) }
      end

      rule(array: subtree(:type)) do
        { 'type' => 'array', 'items' => type }
      end

      rule(pair: { property: simple(:prop), type: subtree(:type) }) do
        { 'properties' => { prop.to_s => type } }
      end

      rule(additional: subtree(:type)) do
        { 'additionalProperties' => type }
      end

      rule(object: subtree(:properties)) do
        { 'type' => 'object' }.tap do |result|
          all_props = Array === properties ? properties : [properties]
          props, additional = all_props.partition {|pr| pr['properties'] }
          props.each do |pr|
            result['properties'] = (result['properties'] || {}).merge(pr['properties'])
          end
          result.update additional.first unless additional.empty?
        end
      end
    end

    def initialize(model_path = Type::MODEL_PATH)
      @parser = Parser.new
      @xform  = Transform.new
      @model_path = model_path
    end

    def parse(str)
      @parser.parse(str)
    end

    def json_schema(str)
      @xform.apply(parse(str), model_path: @model_path)
    rescue Parslet::ParseFailed => e
      raise InvalidTypeError, "'#{str}': #{e.message}"
    end
  end
end
