hash_like_named = proc do |name|
  match do |actual|
    name == (actual.respond_to?(:name) ? actual.name : actual["name"])
  end

  diffable
end

RSpec::Matchers.define(:a_parameter_named, &hash_like_named)
RSpec::Matchers.define(:a_tag_named, &hash_like_named)
RSpec::Matchers.define(:a_property_named, &hash_like_named)
