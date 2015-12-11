require 'spec_helper'

describe SwaggerYard::Property do
  let(:property_obj) { described_class.from_tag(tag) }
  subject(:property) { property_obj.to_h }

  context "with a string type" do
    let(:tag) { yard_tag '@property name [string] Name'  }

    its(['type'])        { is_expected.to eq('string') }
    its(['description']) { is_expected.to eq('Name') }
  end

  context "with a uuid type" do
    let(:tag) { yard_tag '@property name [uuid] Name' }

    its(['type'])        { is_expected.to eq('string') }
    its(['format'])      { is_expected.to eq('uuid') }
  end

  context "with a format option" do
    let(:tag) { yard_tag '@property name [integer<int64>]  Name' }

    its(['type'])        { is_expected.to eq('integer') }
    its(['format'])      { is_expected.to eq('int64') }
  end

  context "with a regex option" do
    let(:tag) { yard_tag '@property name [regex<^.{0,3}$>]  Name' }

    its(['type'])         { is_expected.to eq('string') }
    its(['pattern'])      { is_expected.to eq('^.{0,3}$') }
  end

  context "with an object type" do
    let(:tag) { yard_tag '@property name [object]  Name' }

    its(['type'])        { is_expected.to eq('object') }
    its(['description']) { is_expected.to eq('Name') }
  end

  context "with an array type" do
    let(:tag) { yard_tag '@property names  [array<string>]  Names' }

    its(['type'])           { is_expected.to eq('array') }
    its(['items', 'type'])  { is_expected.to eq('string') }
  end

  context "with a model type" do
    let(:tag) { yard_tag '@property name [Name]   Name' }

    its(['$ref'])   { is_expected.to eq('#/definitions/Name') }
  end

  context "with an array of models" do
    let(:tag) { yard_tag '@property names [array<Name>]  Names' }

    its(['type'])            { is_expected.to eq('array') }
    its(['items', '$ref'])   { is_expected.to eq('#/definitions/Name') }
  end

  context "with an enum" do
    let(:tag) { yard_tag '@property count [enum<one,two,three>]  Count' }

    its(['type'])           { is_expected.to eq('string') }
    its(['enum'])           { is_expected.to eq(['one', 'two', 'three']) }
  end

  context "with a required flag" do
    subject { property_obj }
    let(:tag) { yard_tag '@property name(required) [string]  Name' }

    it { is_expected.to be_required }
  end

  context "with a nullable flag" do
    let(:tag) { yard_tag '@property name(nullable) [string]  Name' }

    its(['type'])           { is_expected.to eq(['string', 'null']) }
    its(['x-nullable'])     { is_expected.to eq(true) }
  end

  context "with a nullable model" do
    let(:tag) { yard_tag '@property name(nullable) [Name]  Name' }

    its(['$ref'])           { is_expected.to eq('#/definitions/Name') }
    its(['x-nullable'])     { is_expected.to eq(true) }
  end

end
