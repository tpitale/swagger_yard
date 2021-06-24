require 'spec_helper'

RSpec.describe SwaggerYard::Swagger do
  subject(:swagger) { SwaggerYard::Swagger.new.to_h }

  it_behaves_like SwaggerYard::Swagger

  it "is valid" do
    errors = Apivore::Swagger.new(swagger).validate
    unless errors.empty?
      require 'pp'
      pp swagger
      puts(*errors)
    end
    expect(errors).to be_empty
  end

  it "includes non-default ports in the host" do
    expect(swagger["host"]).to eq("localhost:3000")
  end

  context "#/paths" do
    subject { swagger["paths"] }

    its(:size) { is_expected.to eq(3) }
  end

  context "#/paths//pets/{id}" do
    subject { swagger["paths"]["/pets/{id}"] }

    it { is_expected.to_not be_empty }

    its(:keys) { are_expected.to eq(["get", "put", "delete"]) }

    its(["get", "summary"]) { is_expected.to eq("return a Pet") }

    its(["get", "operationId"]) { is_expected.to eq("Pet-show") }

    its(["get", "tags"]) { are_expected.to include("Pet") }

    its(["get", "responses"]) { are_expected.to include("default", 404, 400) }

    its(["get", "parameters"]) { are_expected.to include(a_parameter_named("id")) }

    its(["get", "security"]) { is_expected.to eq([{'header_x_application_api_key' => []}])}

    its(["put", "summary"]) { is_expected.to eq("update a Pet") }

    its(["put", "operationId"]) { is_expected.to eq("updatePet") }

    its(["delete", "summary"]) { is_expected.to eq("delete a Pet") }

    its(["delete", "operationId"]) { is_expected.to eq("Pet-destroy") }

    its(["delete", "x-internal"]) { is_expected.to eq("true") }

    context "when ignoring internal paths" do
      before { SwaggerYard.config.ignore_internal = true }

      its(:keys) { are_expected.to eq(["get", "put"]) }
    end

    context "when not defaulting summary to description" do
      before { SwaggerYard.config.default_summary_to_description = false }

      its(["put", "summary"]) { is_expected.to be_nil }
    end
  end

  context "#/paths//pets" do
    subject { swagger["paths"]["/pets"] }

    it { is_expected.to_not be_empty }

    its(:keys) { are_expected.to eq(["get", "post"]) }

    its(["get", "operationId"]) { is_expected.to eq("Pet-index") }

    its(["get", "summary"]) { is_expected.to eq("Index of Pets") }

    its(["get", "description"]) { is_expected.to eq("return a list of Pets") }

    its(["get", "parameters"]) { are_expected.to include(a_parameter_named("client_name")) }

    its(["get", "responses", "default", "examples", "application/json"]) { is_expected.to eq([{"id"=>1, "names"=>["Fido"], "age"=>12}]) }

    its(["post", "operationId"]) { is_expected.to eq("Pet-create") }

    its(["post", "summary"]) { is_expected.to eq("create a Pet") }

    its(["post", "parameters"]) { are_expected.to include(a_parameter_named("pet")) }
  end

  context "#/paths//transports" do
    subject { swagger["paths"]["/transports"] }

    its(["get", "parameters"]) { are_expected.to include(a_parameter_named("sort")) }

    it 'has a sort query parameter containing an enum' do
      param = subject["get"]["parameters"].detect {|p| p["name"] = "sort" }
      expect(param["enum"]).to eq(["id", "wheels"])
      expect(param["type"]).to eq("string")
      expect(param["in"]).to eq("query")
    end
  end

  context "#/definitions" do
    subject(:definitions) { swagger["definitions"] }

    its(:keys) { are_expected.to include("AnimalThing", "Pet", "Pets_Dog", "Possession", "Transport") }

    its(:keys) { are_expected.to_not include("Pets_Domo") }

    its(["AnimalThing", "properties"]) { are_expected.to include("id", "type", "possessions") }

    its(["Pet", "properties"]) { are_expected.to include("id", "names", "age", "relatives") }
    its(["Pet", "properties", "names", "example"]) { is_expected.to eq(["Bob", "Bobo", "Bobby"]) }
    its(["Pet", "properties", "age", "example"]) { is_expected.to eq(8) }
    its(["Pet", "properties", "birthday", "example"]) { is_expected.to eq("2018/10/31T00:00:00.000Z") }

    its(["Possession", "properties"]) { are_expected.to include("name", "value") }

    its(["Transport", "properties"]) { are_expected.to include("id", "wheels") }
    its(["Transport", "example"]) { is_expected.to eq({"id"=>10, "wheels"=>4}) }
  end

  context "#/definitions/Pet" do
    subject { swagger["definitions"]["Pet"] }

    it { is_expected.to_not be_empty }

    its(["required"]) { is_expected.to eq(["id", "relatives"])}

    its(["description"]) { is_expected.to eq("This is the Pet model.")}
  end

  context "#/definitions/Pets_Dog" do
    subject { swagger["definitions"]["Pets_Dog"] }

    its(["allOf"]) { is_expected.to_not be_empty }
    its(["description"]) { is_expected.to eq("A dog model.")}
  end


  context "#/tags" do
    subject { swagger["tags"] }

    it { is_expected.to include(a_tag_named("Pet"), a_tag_named("Transport"))}
  end

  context "#/securityDefinitions" do
    subject { swagger["securityDefinitions"] }

    it { is_expected.to eq("header_x_application_api_key" => {
                             "type" => "apiKey",
                             "name" => "X-APPLICATION-API-KEY",
                             "in" => "header"}) }
  end

  context "models" do
    let(:model) { SwaggerYard::Model.from_yard_object(yard_class('MyModel', content)) }
    let(:spec) { stub(path_objects: SwaggerYard::Paths.new([]), tag_objects: [],
                      security_objects: [], model_objects: { model.id => model }) }

    subject { described_class.new(spec).to_h['definitions'] }

    context "inherited class with polymorphism" do
      let(:content) do
        [
          "@model MyBiggerModel",
          "@inherits MyModel",
          "@property myOtherProperty [string]"
        ].join("\n")
      end

      its(['MyBiggerModel']) do
        is_expected.to eq(
          "allOf" => [
            {
              "$ref" => "#/definitions/MyModel"
            },
            {
              "type" => "object",
              "properties" => {
                "myOtherProperty" => {
                  "type"=>"string"
                }
              }
            }
          ]
        )
      end

      context 'and an external schema' do
        let(:content) do
          ["The description.",
           "",
           "@model MyModel",
           "@inherits schema#OtherModel"].join("\n")
        end
        let(:url)  { 'http://example.com/schemas/v1.0' }
        before do
          SwaggerYard.configure do |config|
            config.external_schema schema: url
          end
        end

        its(['MyModel']) do
          schema = {
            "allOf" => [{ "$ref" => "#{url}#/definitions/OtherModel" }],
            "description" => "The description."
          }
          is_expected.to eq(schema)
        end
      end

      context 'and an external schema with a fragment' do
        let(:content) do
          ["The description.",
           "",
           "@model MyModel",
           "@inherits schema#OtherModel"].join("\n")
        end
        let(:url)  { 'http://example.com/schemas/v1.0#/components/schemas' }
        before do
          SwaggerYard.configure do |config|
            config.external_schema schema: url
          end
        end

        its(['MyModel']) do
          schema = {
            "allOf" => [{ "$ref" => "#{url}/OtherModel" }],
            "description" => "The description."
          }
          is_expected.to eq(schema)
        end
      end

    end

    context 'inherited type with no properties' do
      let(:content) do
        [
         "@model MyEnum",
         "@inherits enum<one,two,three>"
        ].join("\n")
      end

      its(['MyEnum']) do
        is_expected.to eq('type' => 'string', 'enum' => ['one', 'two', 'three'])
      end
    end

    context 'with an empty property' do
      include SilenceLogger
      let(:content) do
        [
          "@model MyModel",
          "@property [string]"
        ].join("\n")
      end

      its(['MyModel']) do
        is_expected.to eq('type' => 'object', 'properties' => {})
      end
    end

    context 'with a typeless property' do
      include SilenceLogger
      let(:content) do
        [
          "@model MyModel",
          "@property myProperty"
        ].join("\n")
      end

      its(['MyModel']) do
        is_expected.to eq('type' => 'object', 'properties' => {})
      end
    end

    context 'with additional properties' do
      let(:content) do
        [
          "@model MyModel",
          "@additional_properties false"
        ].join("\n")
      end

      its(['MyModel']) do
        is_expected.to eq('type' => 'object', 'properties' => {}, 'additionalProperties' => false)
      end
    end

    context 'nullables' do
      subject { super()['MyModel']['properties'] }
      context "with a nullable flag" do
        let(:content) { ['@model MyModel', '@property name(nullable) [string]  Name'] }

        its(['name', 'type'])           { is_expected.to eq(['string', 'null']) }
        its(['name', 'x-nullable'])     { is_expected.to eq(true) }
      end

      context "with a nullable model" do
        let(:content) { ['@model MyModel', '@property name(nullable) [Name]  Name'] }

        its(['name']) { is_expected.to eq('$ref' => '#/definitions/Name') }
      end
    end

    context 'securityDefinitions' do
      let(:auth) { SwaggerYard::Authorization.from_yard_object(yard_tag(content)) }
      let(:spec) { stub(path_objects: SwaggerYard::Paths.new([]), tag_objects: [],
                        security_objects: { auth.id => auth }, model_objects: {}) }
      let (:security_definitions) { {'key' => {'type' => 'basic'} } }

      subject { described_class.new(spec).to_h['securityDefinitions'] }

      before { SwaggerYard.config.security_definitions = security_definitions }

      context 'api key' do
        let(:content) { '@authorization [api_key] header X-My-Header' }

        it { is_expected.to include('header_x_my_header') }

        its(['header_x_my_header']) {
          is_expected.to eq('type' => 'apiKey', 'name' => 'X-My-Header', 'in' => 'header')
        }

        it 'merges config authorizations' do
          expect(subject).to include(security_definitions)
        end
      end

      context 'api key with description' do
        let(:content) { '@authorization [api_key] header X-My-Header Header auth' }

        it { is_expected.to include('header_x_my_header') }

        its(['header_x_my_header']) { is_expected.to eq('type' => 'apiKey', 'name' => 'X-My-Header',
                                                        'in' => 'header', 'description' => 'Header auth') }
      end

      context 'basic' do
        let(:content) { '@authorization [basic] mybasic' }

        it { is_expected.to include('mybasic') }

        its(['mybasic']) { is_expected.to eq('type' => 'basic') }
      end
    end
  end
end
