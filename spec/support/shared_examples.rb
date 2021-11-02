RSpec.shared_examples_for SwaggerYard::Swagger do
  its(["info", "version"]) { is_expected.to eql SwaggerYard.config.api_version }

  its(["paths"]) { are_expected.to_not be_empty }

  its(["definitions"]) { are_expected.to_not be_empty }
end

RSpec.shared_context "person.rb model" do
  let(:objects) do
    SwaggerYard.yard_class_objects_from_file((FIXTURE_PATH + "models" + "person.rb").to_s)
  end

  let(:model) { SwaggerYard::Model.from_yard_object(objects.first) }
end
