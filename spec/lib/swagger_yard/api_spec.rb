require 'spec_helper'

describe SwaggerYard::Api do
  context "with a parsed yard object" do
    let(:yard_object) {stub(docstring: 'A Description')}
    let(:api_group) {SwaggerYard::ApiGroup.new}

    subject(:api) {SwaggerYard::Api.from_yard_object(yard_object, api_group)}

    context "from yard object" do
      let(:tags) { [yard_tag("@path [GET] /accounts/ownerships")] }

      before(:each) do
        yard_object.stubs(:tags).returns(tags)
      end

      its(:path) { is_expected.to eq("/accounts/ownerships") }
    end

    context "with dynamic path discovery" do
      let(:tags) { [] }

      before(:each) do
        yard_object.stubs(:tags).returns(tags)
        yard_object.stubs(:add_tag)
        SwaggerYard.config.path_discovery_function = -> obj do
          expect(obj).to respond_to(:tags)
          ['GET', '/blah']
        end
      end

      its(:path) { is_expected.to eq('/blah') }

      it 'calls the provided function to determine the path' do
        yard_object.expects(:add_tag)
        expect(SwaggerYard::Api.path_from_yard_object(yard_object)).to eq('/blah')
      end

      context "when the function returns nil" do
        before { SwaggerYard.config.path_discovery_function = ->(obj) { nil } }
        its(:path) { is_expected.to be_nil }
      end

      context "when the function raises" do
        include SilenceLogger
        before { SwaggerYard.config.path_discovery_function = ->(obj) { raise "error" } }
        its(:path) { is_expected.to be_nil }
      end
    end
  end
end
