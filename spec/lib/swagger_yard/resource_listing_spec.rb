require 'spec_helper'
require 'tempfile'

RSpec.describe SwaggerYard::ResourceListing, "reparsing" do
  let(:filename) { Tempfile.new(['test_resource', '.rb']).path }
  after { File.unlink filename }

  def resource_listing
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
    hash1 = resource_listing.to_h

    expect(hash1['paths'].keys).to eq(['/hello'])

    File.open(filename, "w") { |f| f.write second_pass }
    hash2 = resource_listing.to_h

    expect(hash2['paths'].keys).to eq(['/hello', '/hello/{msg}'])
  end
end
