require 'spec_helper'

RSpec.describe SwaggerYard::OpenAPI do
  subject(:openapi) { SwaggerYard::OpenAPI.new.to_h }

  its(["openapi"]) { is_expected.to eql('3.0.0') }

  its(["info", "version"]) { is_expected.to eql('1.0') }

  context "#/servers" do
    subject { openapi["servers"] }
    its([0]) { is_expected.to include('url' => 'http://localhost:3000/api') }
  end

  context "#/paths" do
    subject { openapi["paths"] }

    its(:size) { is_expected.to eq(3) }
  end

  context "#/paths//pets/{id}" do
    subject { openapi["paths"]["/pets/{id}"] }

    it { is_expected.to_not be_empty }

    its(:keys) { are_expected.to eq(["get", "delete"]) }

    its(["get", "summary"]) { is_expected.to eq("return a Pet") }

    its(["get", "operationId"]) { is_expected.to eq("Pet-show") }

    its(["get", "tags"]) { are_expected.to include("Pet") }

    its(["get", "responses"]) { are_expected.to include("default", 404, 400) }

    its(["get", "parameters"]) { are_expected.to include(a_parameter_named("id")) }

    its(["get", "security"]) { is_expected.to eq([{'header_x_application_api_key' => []}])}

    its(["delete", "summary"]) { is_expected.to eq("delete a Pet") }

    its(["delete", "operationId"]) { is_expected.to eq("Pet-destroy") }

    its(["delete", "x-internal"]) { is_expected.to eq("true") }

    context "when ignoring internal paths" do
      before { SwaggerYard.config.ignore_internal = true }

      its(:keys) { are_expected.to eq(["get"]) }
    end
  end

  context "#/paths//pets" do
    subject { openapi["paths"]["/pets"] }

    it { is_expected.to_not be_empty }

    its(:keys) { are_expected.to eq(["get", "post"]) }

    its(["get", "operationId"]) { is_expected.to eq("Pet-index") }

    its(["get", "summary"]) { is_expected.to eq("Index of Pets") }

    its(["get", "description"]) { is_expected.to eq("return a list of Pets") }

    its(["get", "parameters"]) { are_expected.to include(a_parameter_named("client_name")) }

    its(["get", "responses", "default", "content", "application/json", "example"]) { is_expected.to eq([{"id"=>1, "names"=>["Fido"], "age"=>12}]) }

    its(["post", "operationId"]) { is_expected.to eq("Pet-create") }

    its(["post", "summary"]) { is_expected.to eq("create a Pet") }

    its(["post", "requestBody", "content",
         "application/json", "schema"]) { is_expected.to include('$ref' => '#/components/schemas/Pet') }

    its(["post", "parameters"]) { are_expected.to_not include(a_parameter_named("pet")) }
  end

  context "#/paths//transports" do
    subject { openapi["paths"]["/transports"] }

    its(["get", "parameters"]) { are_expected.to include(a_parameter_named("sort")) }

    it 'has a sort query parameter containing an enum' do
      param = subject["get"]["parameters"].detect {|p| p["name"] = "sort" }
      expect(param["schema"]["enum"]).to eq(["id", "wheels"])
      expect(param["schema"]["type"]).to eq("string")
      expect(param["in"]).to eq("query")
    end
  end

  context "#/components/schemas" do
    subject(:schemas) { openapi["components"]["schemas"] }

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

  context "#/components/schemas/Pet" do
    subject { openapi["components"]["schemas"]["Pet"] }

    it { is_expected.to_not be_empty }

    its(["required"]) { is_expected.to eq(["id", "relatives"])}

    its(["description"]) { is_expected.to eq("This is the Pet model.")}
  end

  context "#/components/schemas/Pets_Dog" do
    subject { openapi["components"]["schemas"]["Pets_Dog"] }

    its(["allOf"]) { is_expected.to_not be_empty }
    its(["description"]) { is_expected.to eq("A dog model.")}
  end

  context "#/tags" do
    subject { openapi["tags"] }

    it { is_expected.to include(a_tag_named("Pet"), a_tag_named("Transport"))}
  end

  context "#/components/securitySchemes" do
    subject { openapi["components"]["securitySchemes"] }

    it { is_expected.to eq("header_x_application_api_key" => {
                             "type" => "apiKey",
                             "name" => "X-APPLICATION-API-KEY",
                             "in" => "header"}) }
  end

  context 'securityDefinitions' do
    let(:auth) { SwaggerYard::Authorization.from_yard_object(yard_tag(content)) }
    let(:spec) { stub(path_objects: SwaggerYard::Paths.new([]), tag_objects: [],
                      security_objects: { auth.id => auth }, model_objects: {}) }
    let (:security_schemes) { {'key' => {'type' => 'basic', 'description' => 'Basic authentication'} } }
    let(:content) { '@authorization [api_key] header X-My-Header' }

    subject { described_class.new(spec).to_h['components']['securitySchemes'] }

    before { SwaggerYard.config.security_schemes = security_schemes }

    context 'api key' do
      it { is_expected.to include('header_x_my_header') }

      its(['header_x_my_header']) {
        is_expected.to eq('type' => 'apiKey', 'name' => 'X-My-Header', 'in' => 'header')
      }

      it 'merges config authorizations' do
        expect(subject).to include('key' => { 'type' => 'http', 'scheme' => 'basic', 'description' => 'Basic authentication' })
      end
    end

    context 'basic' do
      let(:content) { '@authorization [basic] myBasic This app uses basic authentication' }

      it { is_expected.to include('myBasic') }

      its(['myBasic']) { is_expected.to eq('type' => 'http', 'scheme' => 'basic', 'description' => 'This app uses basic authentication') }
    end

    context 'bearer' do
      let(:content) { '@authorization [bearer] myBearer JWT This app uses JWT authentication' }

      it { is_expected.to include('myBearer') }

      its(['myBearer']) { is_expected.to eq('type' => 'http', 'scheme' => 'bearer', 'bearerFormat' => 'JWT',
                                            'description' => 'This app uses JWT authentication') }
    end

    context 'http' do
      let(:security_schemes) { {'key' => {'type' => 'http', 'scheme' => 'basic', 'description' => 'Basic authentication' } } }

      its(['key']) { is_expected.to eq(security_schemes['key']) }
    end

    context 'with swagger2-style oauth2 config' do
      let(:security_schemes) do
        { 'oauth' => {
            type: "oauth2",
            authorizationUrl: 'http://api.example.com/oauth/authorize',
            tokenUrl: 'http://api.example.com/oauth/token',
            flow: 'implicit'
          }
        }
      end

      its(['oauth']) {
        is_expected.to eq('type' => 'oauth2', 'flows' => {
                            'implicit' => {
                              'authorizationUrl' => 'http://api.example.com/oauth/authorize',
                              'tokenUrl' => 'http://api.example.com/oauth/token',
                              'scopes' => {}
                            }
                          })
      }
    end

    context 'with openapi-style oauth2 config' do
      let(:security_schemes) do
        { 'oauth' => {
            'type' => 'oauth2', 'flows' => {
              'implicit' => {
                'authorizationUrl' => 'http://api.example.com/oauth/authorize',
                'tokenUrl' => 'http://api.example.com/oauth/token',
                'scopes' => {}
              }
            }
          }
        }
      end

      its(['oauth']) {
        is_expected.to eq('type' => 'oauth2', 'flows' => {
                            'implicit' => {
                              'authorizationUrl' => "http://api.example.com/oauth/authorize",
                              'tokenUrl' => 'http://api.example.com/oauth/token',
                              'scopes' => {}
                            }
                          })
      }
    end

  end

  context 'with config.openapi_version set and Swagger.new' do
    subject { SwaggerYard::Swagger.new.to_h }
    before { SwaggerYard.config.openapi_version = '3.0.0' }

    it { is_expected.to include('openapi', 'paths', 'components') }
    it { is_expected.to_not include('swagger', 'definitions') }
  end
end
