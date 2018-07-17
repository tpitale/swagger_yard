require 'spec_helper'

describe SwaggerYard::Property, 'from_tag' do
  subject(:property) { described_class.from_tag(tag) }
  subject { property.type.schema }

  context "with a string type" do
    let(:tag) { yard_tag '@property name [string] Name'  }

    its(['type'])        { is_expected.to eq('string') }
    it { expect(property.description).to eq('Name') }
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
    it { expect(property.description).to eq('Name') }
  end

  context "with an array type" do
    let(:tag) { yard_tag '@property names  [array<string>]  Names' }

    its(['type'])           { is_expected.to eq('array') }
    its(['items', 'type'])  { is_expected.to eq('string') }
  end

  context "with a model type" do
    let(:tag) { yard_tag '@property name [Name]   Name' }

    it { is_expected.to eq('$ref' => '#/definitions/Name') }
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
    subject { property }
    let(:tag) { yard_tag '@property name(required) [string]  Name' }

    it { is_expected.to be_required }
  end

  context "with no description" do
    let(:tag) { yard_tag '@property myProperty [string]' }

    it { is_expected.to eq({'type' => 'string' }) }
  end

  context "with no description (reversed name/type)" do
    let(:tag) { yard_tag '@property [string] myProperty' }

    it { is_expected.to eq({'type' => 'string' }) }
  end

  context 'with no property name' do
    subject { property }
    include SilenceLogger
    let(:tag) { yard_tag '@property [string]' }
    it { is_expected.to be_nil }
  end

  context 'with no type' do
    subject { property }
    include SilenceLogger
    let(:tag) { yard_tag '@property myProperty' }
    it { is_expected.to be_nil }
  end
end

describe SwaggerYard::Property, 'from_method' do
  let(:content) { '' }
  let(:method) { yard_method('foo', content) }
  subject(:property) { described_class.from_method(method) }

  context 'with no content' do
    it { is_expected.to be_nil }
  end

  context 'with no @property tag' do
    let(:content) { 'Hello Foo' }
    it { is_expected.to be_nil }
  end

  context 'with no name' do
    let(:content) { '@property [string]' }
    its(:name) { is_expected.to eq('foo') }
    its('type.name') { is_expected.to eq('string') }
  end

  context 'with a name' do
    let(:content) { '@property [string] hello' }
    its(:name) { is_expected.to eq('foo') }
    its(:description) { is_expected.to eq('hello') }
  end

  context 'with options' do
    let(:content) { '@property [string] (required)' }
    its(:name) { is_expected.to eq('foo') }
    its('type.name') { is_expected.to eq('string') }
    its(:required) { is_expected.to be_truthy }
  end

  context 'with some other tag' do
    let(:content) { '@return [IO] the IO object' }
    it { is_expected.to be_nil }
  end

  context 'with a docstring and a property tag' do
    let(:content) { ['The "foo" property', '@property [Foo]'].join("\n") }
    its(:name) { is_expected.to eq('foo') }
    its('type.name') { is_expected.to eq('Foo') }
    its(:description) { is_expected.to eq('The "foo" property') }
  end

  context 'with an @example' do
    let(:content) { ['@property [Foo]', '@example 1'].join("\n") }
    its(:example) { is_expected.to eq(1) }
  end

  context 'with another @example' do
    let(:content) { ['@property [Foo]', '@example', '  {"type": "Foo"}'].join("\n") }
    its(:example) { is_expected.to eq('type' => 'Foo') }
  end
end
