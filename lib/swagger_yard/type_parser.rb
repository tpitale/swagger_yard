require 'parslet'

module SwaggerYard
  class TypeParser
    class Parser < Parslet::Parser
      # Allow for whitespace surrounding a string value
      def spaced(arg)
        space >> str(arg) >> space
      end

      rule(:space)      { match[" \n"].repeat }

      rule(:id_char)    { match['-a-zA-Z0-9_'].repeat }

      rule(:id_start)   { match('[a-zA-Z_]') }

      rule(:name)       { id_start >> id_char }

      rule(:identifier) { name >> (str('::') >> name).repeat }

      rule(:regexp)     { str('regex') >> str('p').maybe >> space >>
                          str('<') >> (str('\\\\') | str('\\>') | match['[^>]']).repeat.as(:regexp) >> str('>') }

      rule(:enum_list)  { name.as(:value) >> (spaced(',') >> name.as(:value)).repeat }

      rule(:enum)       { str('enum') >> spaced('<') >> enum_list >> spaced('>') }

      rule(:array)      { str('array') >> spaced('<') >> type >> spaced('>') }

      rule(:pair)       { (name.as(:property) >> spaced(':') >> type.as(:type)).as(:pair) }

      rule(:pairs)      { pair >> (spaced(',') >> pair).repeat >> (spaced(',') >> type.as(:additional)).maybe }

      rule(:object)     { str('object') >> spaced('<') >> (pairs | type.as(:additional)) >> spaced('>') }

      rule(:formatted)  { name.as(:name) >> spaced('<') >> name.as(:format) >> spaced('>') }

      rule(:type)       { enum.as(:enum) |
                          array.as(:array) |
                          object.as(:object) |
                          formatted.as(:formatted) |
                          identifier.as(:identifier) |
                          regexp }

      root :type
    end

    class Transform < Parslet::Transform
      rule(identifier: simple(:id)) do
        v = id.to_s
        case v
        when "float", "double"
          { 'type' => 'number', 'format' => v }
        when "date-time", "date", "time", "uuid"
          { 'type' => 'string', 'format' => v }
        else
          name = Model.mangle(v)
          if /[[:upper:]]/.match(name)
            { '$ref' => "#/definitions/#{name}" }
          else
            { 'type' => name }
          end
        end
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
          props, additional = Array(properties).partition {|pr| pr['properties'] }
          props.each do |pr|
            result['properties'] = (result['properties'] || {}).merge(pr['properties'])
          end
          result.update additional.first unless additional.empty?
        end
      end
    end

    def initialize
      @parser = Parser.new
      @xform  = Transform.new
    end

    def parse(str)
      @parser.parse(str)
    end

    def json_schema(str)
      @xform.apply(parse(str))
    rescue Parslet::ParseFailed => e
      raise ArgumentError, "invalid type: #{e.message}"
    end
  end
end
