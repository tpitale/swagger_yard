require 'spec_helper'

RSpec.describe SwaggerYard::Swagger do
  subject(:swagger) { SwaggerYard::Swagger.new.to_h }

  it_behaves_like SwaggerYard::Swagger

  it "is valid" do
    errors = Apivore::Swagger.new(swagger).validate
    puts *errors unless errors.empty?
    expect(errors).to be_empty
  end

  context "#/paths" do
    subject { swagger["paths"] }

    its(:size) { is_expected.to eq(4) }
  end

  context "#/paths//pets/{id}.{format_type}" do
    subject { swagger["paths"]["/pets/{id}.{format_type}"] }

    it { is_expected.to_not be_empty }

    its(:keys) { are_expected.to eq(["get"]) }

    its(["get", "operationId"]) { is_expected.to eq("Pet-show") }

    its(["get", "tags"]) { are_expected.to include("Pet") }

    its(["get", "responses"]) { are_expected.to include("default", "404", "400") }

    its(["get", "parameters"]) { are_expected.to include(a_parameter_named("id"),
                                                       a_parameter_named("format_type")) }

    its(["get", "security"]) { is_expected.to eq([{'header_x_application_api_key' => []}])}
  end

  context "#/definitions" do
    subject(:definitions) { swagger["definitions"] }

    its(:keys) { are_expected.to eq(["AnimalThing", "Pet", "Possession", "Transport"]) }

    its(["AnimalThing", "properties"]) { are_expected.to include("id", "type", "possessions") }

    its(["Pet", "properties"]) { are_expected.to include("id", "names", "age", "relatives") }

    its(["Possession", "properties"]) { are_expected.to include("name", "value") }

    its(["Transport", "properties"]) { are_expected.to include("id", "wheels") }
  end

  context "#/definitions/Pet" do
    subject { swagger["definitions"]["Pet"] }

    it { is_expected.to_not be_empty }

    its(["required"])   { is_expected.to eq(["id", "relatives"])}
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
