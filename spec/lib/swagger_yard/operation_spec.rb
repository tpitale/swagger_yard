require 'spec_helper'

RSpec.describe SwaggerYard::Operation do
  let(:class_name) { 'Hello' }
  let(:api) { stub(api_declaration: stub(resource: 'hello', authorizations: [], class_name: class_name)) }
  let(:tags) { [yard_tag("@path [GET] /hello"), yard_tag("@summary   An summary  ")] }
  let(:yard_object) { stub(docstring: "Hello World", name: :hello, tags: tags) }

  subject(:operation) { described_class.from_yard_object(yard_object, api) }

  its(:path)    { is_expected.to eq("/hello") }
  its(:summary) { is_expected.to eq("An summary") }

  context "with path parameters" do
    let(:tags) { [yard_tag("@path [GET] /hello/{message}")] }

    its(:parameters) { are_expected.to include(a_parameter_named("message")) }
  end

  context "with path parameters and declared parameters" do
    let(:tags) { [yard_tag("@path [GET] /hello/{message}"),
                  yard_tag("@parameter name [string] The person to greet")] }

    its(:parameters) { are_expected.to include(a_parameter_named("message"),
                                               a_parameter_named("name")) }
  end

  context "with path parameters and a matching declared parameter" do
    let(:tags) { [yard_tag("@path [GET] /hello/{message}"),
                  yard_tag("@parameter message [string] The message")] }

    its("parameters.count") { is_expected.to eq(1) }

    its("parameters.first.description") { is_expected.to eq("The message") }

    its("parameters.first.param_type") { is_expected.to eq("path") }

    its("parameters.first.required") { is_expected.to be true }
  end

  context "with a declared parameter followed by a path tag" do
    let(:tags) { [yard_tag("@parameter message [string] The message"),
                  yard_tag("@path [GET] /hello/{message}")] }

    its("parameters.count") { is_expected.to eq(1) }

    its("parameters.first.description") { is_expected.to eq("The message") }

    its("parameters.first.param_type") { is_expected.to eq("path") }

    its("parameters.first.required") { is_expected.to be true }
  end

  context "with a Rails-like controller class that responds to #controller_path" do
    let(:class_name) { stub('Hello', constantize: stub(controller_path: 'my/hello')) }

    subject(:hash) { operation.to_h }

    its(['x-controller']) { is_expected.to eq('my/hello') }
    its(['x-action'])     { is_expected.to eq('hello') }
  end

  context "with a declared parameter that has no description" do
    let(:tags) { [yard_tag("@path [GET] /hello"),
                  yard_tag("@parameter name [string]")] }

    its("parameters.count") { is_expected.to eq(1) }
    its("parameters.last.name") { is_expected.to eq("name") }
    its("parameters.last.description") { is_expected.to eq("name") }
  end

  context "with a declared parameter that has no description (reversed name/type)" do
    let(:tags) { [yard_tag("@path [GET] /hello"),
                  yard_tag("@parameter [string] name")] }

    its("parameters.count") { is_expected.to eq(1) }
    its("parameters.last.name") { is_expected.to eq("name") }
    its("parameters.last.description") { is_expected.to eq("name") }
  end

  context "with multiple body parameters, ignores all but the first one" do
    include SilenceLogger

    let(:tags) { [yard_tag("@path [GET] /hello"),
                  yard_tag("@parameter body(body) [object]"),
                  yard_tag("@parameter name(body) [string]")] }

    its("parameters.count") { is_expected.to eq(1) }
    its("parameters.last.name") { is_expected.to eq("body") }
    its("parameters.last.type.name") { is_expected.to eq("object") }

    it "warns about multiple body parameters" do
      stub_logger.expects(:warn).at_least_once
      subject
    end
  end

  context "with multiple path tags, ignores all but the first path" do
    include SilenceLogger
    let(:tags) { [yard_tag("@path [GET] /hello"),
                  yard_tag("@path [POST] /hello2")] }
    its("path") { is_expected.to eq('/hello') }
    its("http_method") { is_expected.to eq('GET') }

    it "warns about multiple path tags" do
      stub_logger.expects(:warn).at_least_once
      subject
    end
  end
end
