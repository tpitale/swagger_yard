require 'spec_helper'

RSpec.describe SwaggerYard::Swagger do
  subject(:swagger) { SwaggerYard::Swagger.new.swagger_v2.with_indifferent_access }

  it_behaves_like SwaggerYard::Swagger

  context "/pets/{id}.{format_type}" do
    subject { swagger[:paths]["/pets/{id}.{format_type}"] }

    it { is_expected.to_not be_empty }

    its(:keys) { are_expected.to eq(["get"]) }

    its([:get, :responses]) { are_expected.to include(:default, "404", "400") }

    its([:get, :parameters]) { are_expected.to include(a_parameter_named("id"),
                                                       a_parameter_named("format_type")) }
  end

end
