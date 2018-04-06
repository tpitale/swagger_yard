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

    its(:keys) { are_expected.to eq(["get"]) }

    its(["get", "summary"]) { is_expected.to eq("return a Pet") }

    its(["get", "operationId"]) { is_expected.to eq("Pet-show") }

    its(["get", "tags"]) { are_expected.to include("Pet") }

    its(["get", "responses"]) { are_expected.to include("default", "404", "400") }

    its(["get", "parameters"]) { are_expected.to include(a_parameter_named("id")) }

    its(["get", "security"]) { is_expected.to eq([{'header_x_application_api_key' => []}])}
  end

  context "#/paths//pets" do
    subject { swagger["paths"]["/pets"] }

    it { is_expected.to_not be_empty }

    its(:keys) { are_expected.to eq(["get", "post"]) }

    its(["get", "operationId"]) { is_expected.to eq("Pet-index") }

    its(["get", "summary"]) { is_expected.to eq("Index of Pets") }

    its(["get", "description"]) { is_expected.to eq("return a list of Pets") }

    its(["get", "parameters"]) { are_expected.to include(a_parameter_named("client_name")) }

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

    its(["Possession", "properties"]) { are_expected.to include("name", "value") }

    its(["Transport", "properties"]) { are_expected.to include("id", "wheels") }
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
end
