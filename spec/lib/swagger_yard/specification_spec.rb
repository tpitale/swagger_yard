require 'spec_helper'
require 'tempfile'

RSpec.describe SwaggerYard::Specification, "reparsing" do
  let(:fixture_files) do
    fixtures = FIXTURE_PATH + 'specification'
    [
      fixtures + 'hello_controller.rb',
      fixtures + 'goodbye_controller.rb'
    ]
  end

  let(:multi_specification) { described_class.new(fixture_files, nil) }
  let(:filename) { (t = Tempfile.new(['test_resource', '.rb'])).path.tap { t.close! } }

  def specification
    described_class.new filename, nil
  end

  let(:first_pass) do
    <<-SRC
      # @resource Greeting
      class GreetingController
        # @path [GET] /hello
        def index
        end
      end
    SRC
  end

  let(:second_pass) do
    <<-SRC
      # @resource Greeting
      class GreetingController
        # @path [GET] /hello
        def index
        end

        # @path [GET] /hello/{msg}
        # @parameter msg [String] a custom message
        def show
        end
      end
    SRC
  end

  it "reparses after changes to a file" do
    File.open(filename, "w") { |f| f.write first_pass }

    expect(specification.path_objects.paths).to contain_exactly('/hello')

    File.open(filename, "w") { |f| f.write second_pass }

    expect(specification.path_objects.paths).to contain_exactly('/hello', '/hello/{msg}')

    File.unlink filename
  end

  it "supports array arguments for paths" do
    expect(multi_specification.path_objects.paths).to contain_exactly('/bonjour', '/goodbye')
  end

  context '#security_objects' do
    it 'contains  authorizations' do
      expect(multi_specification.security_objects).to_not be_empty
    end
  end

  context '#path_objects' do
    include SilenceLogger

    it 'warns about duplicate operations' do
      stub_logger.expects(:warn).once

      api_group = SwaggerYard::ApiGroup.new
      api_group.resource = 'system'
      api_group.add_yard_object(yard_method(:index, '@path [GET] /accounts'))
      api_group.add_yard_object(yard_method(:index, '@path [GET] /people'))

      spec = specification
      spec.instance_variable_set(:@api_groups, [api_group])
      spec.path_objects
    end
  end
end
