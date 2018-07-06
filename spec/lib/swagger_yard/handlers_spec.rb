require 'spec_helper'

describe SwaggerYard::Handlers do
  include_context 'person.rb model'
  subject { model }

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
