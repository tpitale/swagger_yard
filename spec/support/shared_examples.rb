RSpec.shared_examples_for SwaggerYard::Swagger do
  its([:info, :version]) { is_expected.to eql SwaggerYard.config.api_version }

  its([:paths]) { are_expected.to_not be_empty }

  its([:definitions]) { are_expected.to_not be_empty }
end
