require 'spec_helper'

describe SwaggerYard, '.generate' do
  let(:app_path) {'../../fixtures/dummy/app/'}

  context "for a valid controller" do
    let(:model_path) {File.expand_path(app_path+'models/*.rb', __FILE__)}
    let(:controller_path) {File.expand_path(app_path+'controllers/*.rb', __FILE__)}

    let(:resource_listing) {SwaggerYard::ResourceListing.new(controller_path, model_path)}

    let(:api_json) {File.read(File.expand_path('../../fixtures/api.json', __FILE__))}

    it 'generates swagger api json for the given controllers and models' do
      expect(resource_listing.to_h).to eq(JSON.parse(api_json))
    end

    let(:pets_json) {File.read(File.expand_path('../../fixtures/pets.json', __FILE__))}

    it 'generates swagger json for an individual controller' do
      expect(resource_listing.declaration_for('/pets').to_h).to eq(JSON.parse(pets_json))
    end

    let(:transports_json) {File.read(File.expand_path('../../fixtures/transports.json', __FILE__))}

    it 'generates swagger json for a controller with a response_type model' do
      expect(resource_listing.declaration_for('/transports').to_h).to eq(JSON.parse(transports_json))
    end
  end

  context "for non-controllers (modules) in the path" do
    let(:controllers_path) {File.expand_path('../../fixtures/dummy/app/controllers/**/*.rb', __FILE__)}

    it 'does not error' do
      expect { SwaggerYard::ResourceListing.new(controllers_path, nil).to_h }.to_not raise_error
    end
  end
end
