require 'spec_helper'

describe SwaggerYard::Directives do
  describe SwaggerYard::Directives::ParamClassDirective do
    describe "#call" do
      after { YARD::Registry.clear }

      it "create ClassObject with @model tag" do
        YARD.parse_string <<-EOF
          # @!model Foo
        EOF
        yard_object = YARD::Registry.at("Foo")

        expect(yard_object).to be_a(YARD::CodeObjects::ClassObject)
        expect(yard_object.tags.first.tag_name).to eq("model")
      end

      it "create ClassObject with @model and @property" do
        YARD.parse_string <<-EOF
          # @!model Foo
          # @property id
          # @property name
        EOF
        yard_object = YARD::Registry.at("Foo")

        %w(id name).each do |property|
          expect(yard_object.tags.find do |tag|
            tag.tag_name == "property" && tag.name == property
          end).to_not be_nil
        end
      end

      it "create multiple ClassObject" do
        YARD.parse_string <<-EOF
          # @!model Foo
          # @!model Boo
        EOF

        %w(Foo Boo).each do |model|
          yard_object = YARD::Registry.at(model)
          expect(yard_object).to be_a(YARD::CodeObjects::ClassObject)
          expect(yard_object.tags.first.tag_name).to eq("model")
        end
      end
    end
  end

  describe SwaggerYard::Directives::PathDirective do
    describe "#call" do
      after { YARD::Registry.clear }

      it "create ClassObject with @path tag" do
        YARD.parse_string <<-EOF
          # @!path [GET] /endpoint
        EOF
        yard_object = YARD::Registry.at("#/endpoint_GET")

        expect(yard_object).to be_a(YARD::CodeObjects::MethodObject)
        expect(yard_object.tags.first.tag_name).to eq("path")
        expect(yard_object.tags.first.text).to eq("/endpoint")
        expect(yard_object.tags.first.types.first).to eq("GET")
      end
    end
  end
end
