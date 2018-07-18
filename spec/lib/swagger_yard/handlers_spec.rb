require 'spec_helper'

describe SwaggerYard::Handlers do
  include_context 'person.rb model'
  subject { model }

  its('properties') { is_expected.to include(a_property_named('address'),
                                             a_property_named('age')) }

  its('properties') { is_expected.to include(a_property_named('country')) }

  its('properties') { is_expected.to_not include(a_property_named('age=')) }

  its('properties') { is_expected.to_not include(a_property_named('country=')) }

  it 'uses the docstring description' do
    country = model.property('country')
    expect(country.description).to eq("The person's country")
  end

  describe 'method properties with a DSL method registered' do
    before do
      SwaggerYard.configure do |config|
        config.register_dsl_method :def_delegators, args: (1..-1)
      end
    end

    its('properties') { is_expected.to include(a_property_named('first_name'),
                                               a_property_named('last_name')) }

    its('properties') { is_expected.to_not include(a_property_named('get_parent')) }

    it 'hands requiredness to each DSL method' do
      first_name = model.property('first_name')
      expect(first_name).to be_required
    end
  end
end
