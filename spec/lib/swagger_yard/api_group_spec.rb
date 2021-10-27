require 'spec_helper'

describe SwaggerYard::ApiGroup do
  context "with a parsed yard object" do
    let(:yard_object) { yard_method(:index, ['A Description', *tags].join("\n")) }
    let(:api_group) { SwaggerYard::ApiGroup.new }
    subject(:path) { api_group.add_path_item(yard_object) }

    context "from yard object" do
      let(:tags) { ["@path [GET] /accounts/ownerships"] }

      it { is_expected.to eq("/accounts/ownerships") }
    end

    context "with dynamic path discovery" do
      let(:tags) { [] }

      before(:each) do
        SwaggerYard.config.path_discovery_function = -> obj do
          expect(obj).to respond_to(:tags)
          ['GET', '/blah']
        end
      end

      it { is_expected.to eq('/blah') }

      it 'calls the provided function to determine the path' do
        yard_object.expects(:add_tag)
        expect(api_group.path_from_yard_object(yard_object)).to eq('/blah')
      end

      context "when the function returns nil" do
        before { SwaggerYard.config.path_discovery_function = ->(obj) { nil } }
        it { is_expected.to be_nil }
      end

      context "when the function raises" do
        include SilenceLogger
        before { SwaggerYard.config.path_discovery_function = ->(obj) { raise "error" } }
        it { is_expected.to be_nil }
      end
    end
  end

  describe 'visibility' do
    let(:fixture_files) do
      controllers_fixtures_path = "#{FIXTURE_PATH.to_s}/specification"
      %w[hello_controller.rb goodbye_controller.rb fully_private_controller.rb semi_private_controller.rb].map { |f| "#{controllers_fixtures_path}/#{f}" }
    end

    let(:yard_objects) do
      fixture_files.map { |f| SwaggerYard.yard_objects_from_file(f, :class) }.flatten
    end

    context 'include private' do
      before { SwaggerYard.config.include_private = true }
      it 'should add private resources if include_private is true' do
        groups = []
        expect(yard_objects.count).to eq 4
        yard_objects.each { |o| groups << SwaggerYard::ApiGroup.new.add_yard_object(o) }
        resources = groups.map { |g| g.resource }.keep_if { |r| !r.nil? }
        paths = groups.map { |g| g.path_items.keys }.flatten.keep_if { |p| !p.nil? }
        expect(resources).to contain_exactly(*%w[Bonjour Farewell FullyPrivate SemiPrivate])
        expect(paths).to contain_exactly(*%w[/bonjour /goodbye /fully_private /semi_private_public /semi_private])
      end
    end

    context 'exclude private' do
      before { SwaggerYard.config.include_private = false }
      it 'should ignore private resources if include_private is false' do
        groups = []
        expect(yard_objects.count).to eq 4
        yard_objects.each { |o| groups << SwaggerYard::ApiGroup.new.add_yard_object(o) }
        resources = groups.map { |g| g.resource }.keep_if { |r| !r.nil? }
        paths = groups.map { |g| g.path_items.keys }.flatten.keep_if { |p| !p.nil? }
        expect(resources).to contain_exactly(*%w[Bonjour Farewell SemiPrivate])
        expect(paths).to contain_exactly(*%w[/bonjour /goodbye /semi_private_public])
      end
    end
  end
end
