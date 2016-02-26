require 'spec_helper'

RSpec.describe SwaggerYard::Model do
  let(:tags) do
    [
      yard_tag("@model MyModel"),
      yard_tag("@discriminator myType(required) [string]")
    ]
  end

  let(:object)    { stub(tags: tags) }
  subject(:model) { described_class.from_yard_object(object) }

  its(:id) { is_expected.to eq("MyModel") }

  context "with characters that are not components of a word" do
    let(:tags) { [yard_tag("@model MyApp::Models::Foo")] }

    its(:id) { is_expected.to eq("MyApp_Models_Foo") }
  end

  context "with numeric or _ characters" do
    let(:tags) { [yard_tag("@model My__Model01")] }

    its(:id) { is_expected.to eq("My__Model01") }
  end

  context "superclass with polymorphism" do
    its(:discriminator) { is_expected.to eq("myType") }
  end

  context "inherited class with polymorphism" do
    let(:tags) do
      [
        yard_tag("@model MyBiggerModel"),
        yard_tag("@inherits MyModel"),
        yard_tag("@property myOtherProperty [string]")
      ]
    end

    its(:to_h) do
      is_expected.to eq(
        "allOf" => [
          {
            "$ref" => "#/definitions/MyModel"
          },
          {
            "type" => "object",
            "properties" => {
              "myOtherProperty" => {
                "type"=>"string",
                "description"=>""
              }
            }
          }
        ]
      )
    end
  end
end
