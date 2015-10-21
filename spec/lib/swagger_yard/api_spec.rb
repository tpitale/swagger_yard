require 'spec_helper'

describe SwaggerYard::Api do
  context "with a parsed yard object" do
    let(:yard_object) {stub(docstring: 'A Description')}
    let(:api_declaration) {SwaggerYard::ApiDeclaration.new(nil)}

    let(:api) {SwaggerYard::Api.from_yard_object(yard_object, api_declaration)}

    context "from yard object" do
      let(:tags) { [stub(tag_name: "path", types: ["GET"], text: "/accounts/ownerships.{format_type}")] }

      before(:each) do
        yard_object.stubs(:tags).returns(tags)
      end

      it 'to have a path' do
        expect(api.path).to eq("/accounts/ownerships.{format_type}")
      end
    end

    context "with dynamic path discovery" do
      let(:tags) { [] }

      before(:each) do
        yard_object.stubs(:tags).returns(tags)
        SwaggerYard.configure do |config|
          @prev_fn = config.path_discovery_function
          config.path_discovery_function = -> obj do
            expect(obj).to respond_to(:tags)
            '/blah'
          end
        end
      end

      after(:each) do
        SwaggerYard.configure do |config|
          config.path_discovery_function = @prev_fn
        end
      end

      it 'calls the provided function to determine the path' do
        expect(api.path).to eq('/blah')
      end
    end
  end
end
