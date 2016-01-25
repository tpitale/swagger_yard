require 'spec_helper'

RSpec.describe SwaggerYard::Type do
  def type(t)
    described_class.from_type_list([t])
  end

  it 'mangles the type names of models' do
    expect(type('MyApp::Greeting').name).to eq('MyApp_Greeting')
  end

  it 'mangles the type names in an array' do
    expect(type('array<MyApp::Greeting>').name).to eq('MyApp_Greeting')
  end

  it 'does not mangle names that only contain identifier characters' do
    expect(type('MyApp__Greeting').name).to eq('MyApp__Greeting')
  end
end
