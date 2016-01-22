hash_like_named = proc do |name|
  match do |actual|
    actual.to_h['name'] == name
  end

  diffable
end

RSpec::Matchers.define(:a_parameter_named, &hash_like_named)
RSpec::Matchers.define(:a_tag_named, &hash_like_named)
