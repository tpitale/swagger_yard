require 'spec_helper'

describe SwaggerYard, '.generate' do
  let(:app_path)        {'../../fixtures/dummy/app/'}
  let(:model_path)      {File.expand_path(app_path+'models/**/*.rb', __FILE__)}
  let(:controller_path) {File.expand_path(app_path+'controllers/**/*.rb', __FILE__)}

  subject(:resource_listing) { SwaggerYard::ResourceListing.new(controller_path, model_path) }

  context "json" do
    subject { resource_listing.to_h }

    it { is_expected.to include("paths", "definitions", "tags", "securityDefinitions") }
  end

  context "paths" do
    subject { resource_listing.to_h["paths"] }

    its(:size) { is_expected.to eq(4) }

  end

  context "tags" do
    subject(:tags) { resource_listing.to_h["tags"] }

    specify "have all resource tags" do
      expect(tags.map{|h| h["name"]}).to eq(["Pet", "Transport"])
    end
  end

  context "definitions" do
    subject(:definitions) { resource_listing.to_h["definitions"] }

    its(:keys) { are_expected.to eq(["AnimalThing", "Pet", "Possession", "Transport"]) }

    its(["AnimalThing", "properties"]) { are_expected.to include("id", "type", "possessions") }

    its(["Pet", "properties"]) { are_expected.to include("id", "names", "age", "relatives") }

    its(["Possession", "properties"]) { are_expected.to include("name", "value") }

    its(["Transport", "properties"]) { are_expected.to include("id", "wheels") }
  end

  context "securityDefinitions" do
    subject(:security) { resource_listing.to_h["securityDefinitions"] }

    its(:keys) { are_expected.to eq(["header_x_application_api_key"]) }

    its(["header_x_application_api_key"]) {
      is_expected.to eq({ "type" => "apiKey",
                          "name" => "X-APPLICATION-API-KEY",
                          "in"   => "header" })
    }
  end

  context "for non-controllers (modules) in the path" do
    it 'does not error' do
      expect { resource_listing.to_h }.to_not raise_error
    end

    it 'does not create resources that are not tagged as @resource' do
      expect(resource_listing.controllers.detect {|c|
               c.description =~ /NotAResourceController/ }).to be_nil
    end
  end
end
