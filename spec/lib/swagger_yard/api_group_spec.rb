require 'spec_helper'

describe SwaggerYard::ApiGroup do
  context "with a parsed yard object" do
    let(:yard_object) { yard_method(:index, ['A Description', *tags].join("\n")) }
    let(:api_group) { SwaggerYard::ApiGroup.new }
    subject(:path) { api_group.add_path_item(yard_object) }

    context "from yard object" do
      let(:tags) { ["@path [GET] /accounts/ownerships"] }

      it { is_expected.to eq("/accounts/ownerships") }
    end

    context "with dynamic path discovery" do
      let(:tags) { [] }

      before(:each) do
        SwaggerYard.config.path_discovery_function = -> obj do
          expect(obj).to respond_to(:tags)
          ['GET', '/blah']
        end
      end

      it { is_expected.to eq('/blah') }

      it 'calls the provided function to determine the path' do
        yard_object.expects(:add_tag)
        expect(api_group.path_from_yard_object(yard_object)).to eq('/blah')
      end

      context "when the function returns nil" do
        before { SwaggerYard.config.path_discovery_function = ->(obj) { nil } }
        it { is_expected.to be_nil }
      end

      context "when the function raises" do
        include SilenceLogger
        before { SwaggerYard.config.path_discovery_function = ->(obj) { raise "error" } }
        it { is_expected.to be_nil }
      end
    end
  end
end
