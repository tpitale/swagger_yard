require 'spec_helper'

RSpec.describe SwaggerYard::TypeParser do
  subject { described_class.new }

  context "#parse" do

    it { parses 'object' }

    it { parses 'Foo' }

    it { parses 'Foo::Bar' }

    it { parses '(Foo | Bar)' }

    it { parses '(Foo & Bar)' }

    it { parses '(Foo | Bar | Baz)' }

    it { parses '(Foo | (Bar & Baz))' }

    it { parses 'prefix#Length' }

    it { parses 'prefix#Foo::Bar' }

    it { parses 'array<string>' }

    it { parses 'array< string >' }

    it { parses 'array<Foo::Bar>' }

    it { parses '(array<Foo::Bar>|array<Quux>)' }

    it { parses '(prefix#Bar&prefix#Quux)' }

    it { parses 'array<prefix#Foo::Bar>' }

    it { parses 'object<name:string,email:Foo::Bar>' }

    it { parses 'object<name:string,email:prefix#Foo::Bar>' }

    it { parses 'object< name : string  ,  email :   string  >' }

    it { parses 'object<name:string,email:string,string>' }

    it { parses 'object<name: string , email: string ,  string  >' }

    it { parses 'object<pairs:array<object<right:integer,left:integer>>>' }

    it { parses 'enum<one,two,three>' }

    it { parses 'enum< one, two, three >' }

    it { parses 'integer<int32>' }

    it { parses 'regexp<blah>' }

    it { parses 'regex<blah>' }

    it { parses 'regexp<^.*$>' }

    it { parses 'regexp<.\\>.>' }

    it { parses 'regexp< a b c >' }

    it { does_not_parse 'Foo::Bar,array<Hello>' }

    it { does_not_parse 'enum<array<string>>' }

    it { does_not_parse 'integer<int32,int64>' }

    it { does_not_parse '( Foo | Bar & Baz )'}

    it { does_not_parse 'regexp<.>.>' }

    it { does_not_parse 'regexp<.\\\\>.>' }

    it { expect_parse_to 'Foo' => { identifier: 'Foo' } }

    it { expect_parse_to 'Foo::Bar' => { identifier: 'Foo::Bar' } }

    it { expect_parse_to 'prefix#Foo::Bar' => { external_identifier: { namespace: 'prefix', identifier: 'Foo::Bar' } } }

    it { expect_parse_to 'AnObject' => { identifier: 'AnObject' } }

    it { expect_parse_to 'object' => { identifier: 'object' } }

    it { expect_parse_to 'array<string>' => { array: { identifier: 'string' } } }

    it { expect_parse_to 'enum<one>' => { enum: { value: 'one' } } }

    it { expect_parse_to 'regexp<^.*$>' => { regexp: '^.*$' } }

    it { expect_parse_to 'enum<one, two, three>' => { enum: [{ value: 'one' }, { value: 'two'}, { value: 'three'}] } }

    it { expect_parse_to 'regexp<^.*$>' => { regexp: '^.*$' } }

    it { expect_parse_to 'regexp<.\>.>' => { regexp: '.\>.' } }

    it { expect_parse_to 'regexp< a b c >' => { regexp: ' a b c ' }  }

    it { expect_parse_to 'regex< a b c >' => { regexp: ' a b c ' }  }

    it { expect_parse_to 'object<a:integer,b:boolean>' => { object: [{ pair: { property: 'a', type: { identifier: 'integer' } } },
                                                                     { pair: { property: 'b', type: { identifier: 'boolean' } } }] } }

    it { expect_parse_to 'object<integer>' => { object: { additional: { identifier: 'integer' } } } }

    it {
      expect_parse_to 'array<prefix#Length>' => { array: { external_identifier: { namespace: 'prefix', identifier: 'Length' } } }
    }

    it { expect_parse_to '(Foo | Bar)' => { union: [{ identifier: 'Foo' },
                                                    { identifier: 'Bar' }]} }

    it { expect_parse_to '(Foo & Bar)' => { intersect: [{ identifier: 'Foo' },
                                                        { identifier: 'Bar' }]} }

    it { expect_parse_to '(Foo | (Bar & Baz))' => { union: [{ identifier: 'Foo' },
                                                            { intersect: [{ identifier: 'Bar' },
                                                                          { identifier: 'Baz' }]}]} }

    it {
      expect_parse_to 'object<pairs:array<object<right:integer,left:integer>>>' => {
        object: {
          pair: { property: 'pairs',
              type: { array: {
                  object: [{ pair: { property: 'right', type: { identifier: 'integer' }}},
                           { pair: { property: 'left',  type: { identifier: 'integer' }}}]
                } } } }
      }
    }

    it {
      expect_parse_to 'object<a:string,b:string,object>' => {
        object: [{ pair: { property: 'a', type: { identifier: 'string' }}},
                 { pair: { property: 'b', type: { identifier: 'string' }}},
                 { additional: { identifier: 'object' }}]
      }
    }

    it { expect_parse_to 'integer<int32>' => { formatted: { name: 'integer', format: 'int32' } } }

  end

  context "#json_schema" do

    def expect_json_schema(hash)
      hash.each do |k,v|
        expect(subject.json_schema(k)).to eq(v)
      end
    end

    it { expect_json_schema 'integer' => { "type" => "integer" } }

    it { expect_json_schema 'object' => { "type" => "object" } }

    it { expect_json_schema 'Object' => { "type" => "object" } }

    it { expect_json_schema 'array' => { "type" => "array", "items" => { "type" => "string" } } }

    it { expect_json_schema 'Array' => { "type" => "array", "items" => { "type" => "string" } } }

    ["float", "double"].each do |t|
      it { expect_json_schema t => { "type" => "number", "format" => t } }
    end

    ["date-time", "date", "time", "uuid"].each do |t|
      it { expect_json_schema t => { "type" => "string", "format" => t } }
    end

    it { expect_json_schema 'float' => { "type" => "number", "format" => "float" } }

    it { expect_json_schema 'integer<int32>' => { "type" => "integer", "format" => "int32" } }

    it { expect_json_schema 'regexp<^.*$>' => { "type" => "string", "pattern" => "^.*$" } }

    it { expect_json_schema 'regexp<.\\>.>' => { "type" => "string", "pattern" => ".>." } }

    it { expect_json_schema 'regexp<.\\\\\\>.>' => { "type" => "string", "pattern" => ".\\>." } }

    it { expect_json_schema 'regexp< a b c >' => { "type" => "string", "pattern" => " a b c " } }

    it { expect_json_schema 'Foo' => { "$ref" => "#/definitions/Foo" } }

    it { expect_json_schema 'AnArray' => { "$ref" => "#/definitions/AnArray" } }

    it { expect_json_schema 'AnObject' => { "$ref" => "#/definitions/AnObject" } }

    it { expect_json_schema 'Foo::Bar' => { "$ref" => "#/definitions/Foo_Bar" } }

    it { expect_json_schema 'array<string>' => { "type" => "array", "items" => { "type" => "string" } } }

    it { expect_json_schema 'Array<string>' => { "type" => "array", "items" => { "type" => "string" } } }

    it { expect_json_schema 'array<Foo::Bar>' => { "type" => "array", "items" => { "$ref" => "#/definitions/Foo_Bar" } } }

    it { expect_json_schema 'enum<one>' => { "type" => "string", "enum" => %w(one) } }

    it { expect_json_schema 'Enum<one>' => { "type" => "string", "enum" => %w(one) } }

    it { expect_json_schema 'enum<one,two,three>' => { "type" => "string", "enum" => %w(one two three) } }

    it {
      expect_json_schema 'object<a:integer,b:boolean>' => {
        "type" => "object",
        "properties" => {
          "a" => { "type" => "integer" },
          "b" => { "type" => "boolean" } }
      }
    }

    it {
      expect_json_schema 'object<a:integer,b:boolean,string>' => {
        "type" => "object",
        "properties" => {
          "a" => { "type" => "integer" },
          "b" => { "type" => "boolean" } },
        "additionalProperties" => { "type" => "string" }
      }
    }

    it {
      expect_json_schema 'array<object<a:integer,b:boolean>>' => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "a" => { "type" => "integer" },
            "b" => { "type" => "boolean" } }
        }
      }
    }

    it {
      expect_json_schema '(Foo | Bar)' => {
        'oneOf' => [{ "$ref" => "#/definitions/Foo" },
                    { "$ref" => "#/definitions/Bar" }]
      }
    }

    it {
      expect_json_schema '(Foo & Bar)' => {
        'allOf' => [{ "$ref" => "#/definitions/Foo" },
                    { "$ref" => "#/definitions/Bar" }]
      }
    }

    it {
      expect_json_schema '(Foo | (Bar & Baz))' => {
        'oneOf' => [{ "$ref" => "#/definitions/Foo" },
                    { 'allOf' => [{ "$ref" => "#/definitions/Bar" },
                                  { "$ref" => "#/definitions/Baz" }]}]
      }
    }

    it 'raises an error when the type cannot be parsed' do
      expect do
        subject.json_schema('Length; array<object>')
      end.to raise_error(SwaggerYard::InvalidTypeError)
    end

    it 'raises an error when a prefix is not configured' do
      expect do
        subject.json_schema('prefix#Length')
      end.to raise_error(SwaggerYard::UndefinedSchemaError)
    end

    context 'with external schema' do
      let(:url) { 'http://example.com/schemas/v1.0' }
      before do
        SwaggerYard.configure do |config|
          config.external_schema prefix: url
        end
      end

      it { expect_json_schema 'prefix#Length' => { "$ref" => "#{url}#/definitions/Length" } }
    end

    context 'with external file' do
      let(:file1) { 'file:///etc/schemas/v1.0/file.json#/defs' }
      let(:file2) { 'file:/etc/schemas/v1.0/file.json#/defs' }

      before do
        SwaggerYard.configure do |config|
          config.external_schema prefix1: file1
          config.external_schema prefix2: file2
        end
      end

      # URI('file:') differs in the number of slashes between Ruby 2.4 and 2.5.
      # <= 2.4 would convert to 'file:/' with a single slash
      # >= 2.5 would convert to 'file:///' with three slashes
      # Test here that SY does not change the uri that was registered.
      it { expect_json_schema 'prefix1#Length' => { "$ref" => "#{file1}/Length" } }
      it { expect_json_schema 'prefix2#Length' => { "$ref" => "#{file2}/Length" } }
    end
  end
end
