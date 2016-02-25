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

  describe '#to_h' do
    it 'handles additionalProperties with uniform simple key-values' do
      expect(type('object<string>').to_h).to eq({
        "type" => "object",
        "additionalProperties" => {
          "type" => "string"
        }
      })
    end

    it 'handles additionalProperties with uniform model key-values' do
      expect(type('object<MyApp::Greeting>').to_h).to eq({
        "type" => "object",
        "additionalProperties" => {
          "$ref" => "#/definitions/MyApp_Greeting"
        }
      })
    end

    it 'handles additionalProperties with uniform key-values of arrays of models' do
      expect(type('object<array<MyApp::Greeting>>').to_h).to eq({
        "type" => "object",
        "additionalProperties" => {
          "type" => "array",
          "items" => {
            "$ref" => "#/definitions/MyApp_Greeting"
          }
        }
      })
    end

    it 'handles nested object definitions' do
      expect(type('object<object<string>>').to_h).to eq({
        "type" => "object",
        "additionalProperties" => {
          "type" => "object",
          "additionalProperties" => {
            "type" => "string"
          }
        }
      })
    end
  end
end
