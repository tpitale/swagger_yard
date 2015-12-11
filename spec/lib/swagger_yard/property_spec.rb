require 'spec_helper'

describe SwaggerYard::Property do
  let(:property_obj) { described_class.from_tag(tag) }
  subject(:property) { property_obj.to_h }

  context "with a string type" do
    let(:tag) { stub name: 'name', types: ['string'], text: 'Name' }

    its(['type'])        { is_expected.to eq('string') }
    its(['description']) { is_expected.to eq('Name') }
  end

  context "with a uuid type" do
    let(:tag) { stub name: 'name', types: ['uuid'], text: 'Name' }

    its(['type'])        { is_expected.to eq('string') }
    its(['format'])      { is_expected.to eq('uuid') }
  end

  context "with a format option" do
    let(:tag) { stub name: 'name', types: ['integer<int64>'], text: 'Name' }

    its(['type'])        { is_expected.to eq('integer') }
    its(['format'])      { is_expected.to eq('int64') }
  end

  context "with a regex option" do
    let(:tag) { stub name: 'name', types: ['regex<^.{0,3}$>'], text: 'Name' }

    its(['type'])         { is_expected.to eq('string') }
    its(['pattern'])      { is_expected.to eq('^.{0,3}$') }
  end

  context "with an object type" do
    let(:tag) { stub name: 'name', types: ['object'], text: 'Name' }

    its(['type'])        { is_expected.to eq('object') }
    its(['description']) { is_expected.to eq('Name') }
  end

  context "with an array type" do
    let(:tag) { stub name: 'names', types: ['array<string>'], text: 'Name' }

    its(['type'])           { is_expected.to eq('array') }
    its(['items', 'type'])  { is_expected.to eq('string') }
  end

  context "with a model type" do
    let(:tag) { stub name: 'name', types: ['Name'], text: 'Name' }

    its(['$ref'])   { is_expected.to eq('#/definitions/Name') }
  end

  context "with an array of models" do
    let(:tag) { stub name: 'names', types: ['array<Name>'], text: 'Name' }

    its(['type'])            { is_expected.to eq('array') }
    its(['items', '$ref'])   { is_expected.to eq('#/definitions/Name') }
  end

  context "with an enum" do
    let(:tag) { stub name: 'count', types: ['enum<one,two,three>'], text: 'Count' }

    its(['type'])           { is_expected.to eq('string') }
    its(['enum'])           { is_expected.to eq(['one', 'two', 'three']) }
  end

  context "with a required flag" do
    subject { property_obj }
    let(:tag) { stub name: 'name(required)', types: ['string'], text: 'Name' }

    it { is_expected.to be_required }
  end

  context "with a nullable flag" do
    let(:tag) { stub name: 'name(nullable)', types: ['string'], text: 'Name' }

    its(['type'])           { is_expected.to eq(['string', 'null']) }
    its(['x-nullable'])     { is_expected.to eq(true) }
  end

  context "with a nullable model" do
    let(:tag) { stub name: 'name(nullable)', types: ['Name'], text: 'Name' }

    its(['$ref'])           { is_expected.to eq('#/definitions/Name') }
    its(['x-nullable'])     { is_expected.to eq(true) }
  end

end
