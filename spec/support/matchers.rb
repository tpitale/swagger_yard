hash_like_named = proc do |name|
  match do |actual|
    actual = actual.to_h unless actual.is_a? Hash
    actual['name'] == name
  end

  diffable
end

RSpec::Matchers.define(:a_parameter_named, &hash_like_named)
RSpec::Matchers.define(:a_tag_named, &hash_like_named)
