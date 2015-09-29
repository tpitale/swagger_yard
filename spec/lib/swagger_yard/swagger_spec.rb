require 'spec_helper'

RSpec.describe SwaggerYard::Swagger do
  subject(:swagger) { SwaggerYard::Swagger.new.swagger_v2 }

  it_behaves_like SwaggerYard::Swagger
end
