RSpec::Matchers.define :a_parameter_named do |name|
  match do |actual|
    actual['name'] == name
  end

  diffable
end
