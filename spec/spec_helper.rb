require 'teeth/tokenize_apache_logs'

def be_greater_than(expected)
  simple_matcher("be greater than #{expected.to_s}") do |given, matcher|
    matcher.failure_message = "expected #{given.to_s} to be greater than #{expected.to_s}"
    matcher.negative_failure_message = "expected #{given.to_s} to not be greater than #{expected.to_s}"
    given > expected
  end
  
end
