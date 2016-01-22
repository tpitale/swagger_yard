require 'spec_helper'

RSpec.describe SwaggerYard::Model do
  let(:tags) { [yard_tag("@model MyModel")] }
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
end
