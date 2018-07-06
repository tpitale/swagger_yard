require 'spec_helper'

RSpec.describe SwaggerYard::Model do
  let(:content) do
    [ "@model MyModel",
      "@discriminator myType(required) [string]" ].join("\n")
  end

  let(:object)    { yard_class('MyModel', content) }

  subject(:model) { described_class.from_yard_object(object) }

  its(:id) { is_expected.to eq("MyModel") }

  context "with characters that are not components of a word" do
    let(:content) { "@model MyApp::Models::Foo" }

    its(:id) { is_expected.to eq("MyApp_Models_Foo") }
  end

  context "with numeric or _ characters" do
    let(:content) { "@model My__Model01" }

    its(:id) { is_expected.to eq("My__Model01") }
  end

  context "superclass with polymorphism" do
    its(:discriminator) { is_expected.to eq("myType") }
  end

  context "with only @model" do
    let(:content) { "@model" }

    its(:id) { is_expected.to eq("MyModel") }

    context "and a namespaced class name" do
      let(:object) { yard_class('MyApp::MyModel', content) }

      its(:id) { is_expected.to eq('MyApp_MyModel') }
    end
  end

  context "with a description" do
    let(:desc) {"This is my class. Not your class."}
    let(:content) do
      [desc, "", "@model MyModel"].join("\n")
    end
    its(:description) { is_expected.to eq(desc) }
  end

  context "with no @model tag" do
    let(:content) { "Some description without a SwaggerYard model tag" }

    it { is_expected.to_not be_valid }
  end

  context "with an @example" do
    let(:content) do
      ["@model MyModel",
       '@example',
       '  {',
       '    "key": "value"',
       '  }'
      ].join("\n")
    end

    its(:example) { is_expected.to eq('key' => 'value') }
  end

  context "with an @example tied to a property" do
    let(:content) do
      ['@model MyModel',
       '@property [string] name',
       '@example name',
       '  "Nick"'
      ].join("\n")
    end

    it 'sets the example on the property' do
      prop = model.property('name')
      expect(prop.example).to eq("Nick")
    end
  end

  context 'with method properties' do
    let(:objects) do
      SwaggerYard.yard_class_objects_from_file((FIXTURE_PATH + 'models' + 'person.rb').to_s)
    end

    subject(:model) { SwaggerYard::Model.from_yard_object(objects.first) }

    its('properties') { is_expected.to include(a_property_named('address'),
                                               a_property_named('parent'),
                                               a_property_named('age')) }

    its('properties') { is_expected.to_not include(a_property_named('some_non_model_method'),
                                                   a_property_named('get_parent')) }

    it 'captures the type' do
      address = model.property('address')
      expect(address.type.name).to eq('Address')
    end

    it 'captures the description' do
      address = model.property('address')
      expect(address.description).to eq("the person's address")
    end

    it 'captures requiredness' do
      age = model.property('age')
      expect(age).to be_required
    end
  end
end
