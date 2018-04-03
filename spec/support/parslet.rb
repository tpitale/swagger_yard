# Patch ParseFailed to be better behaved for RSpec
class Parslet::ParseFailed
  remove_method :cause if instance_methods(false).include?(:cause)
end

RSpec::Matchers.define :parse do |str,*rest|
  match do |parser|
    begin
      @result = parser.parse(str)
      if rest.empty?
        @result
      else
        @result == rest.first
      end
    rescue Parslet::ParseFailed
      false
    end
  end

  failure_message do
    "expected '#{str}' to parse".tap do |msg|
      unless rest.empty?
        msg << " result:\n  expected: #{rest.first.inspect}\n  actual:   #{@result.inspect}"
      end
    end
  end

  match_when_negated do |parser|
    begin
      parser.parse(str)
      false
    rescue Parslet::ParseFailed
      true
    end
  end

  failure_message_when_negated do
    "expected '#{str}' to not parse"
  end
end

module ParseHelpers
  def expect_parse_to(hash)
    hash.each do |k,v|
      expect(subject).to parse(k, v)
    end
  end

  def parses(str)
    expect(subject).to parse(str)
  end

  def does_not_parse(str)
    expect(subject).to_not parse(str)
  end
end

RSpec.configure do |c|
  c.include ParseHelpers
end
