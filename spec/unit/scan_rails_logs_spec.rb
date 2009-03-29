require File.dirname(__FILE__) + '/../spec_helper'

# special shout out to Willem van Bergen, author of request-log-analyzer:
# http://github.com/wvanbergen/request-log-analyzer/
# Stole the rails request logs from there...

describe "Rails Request Log Lexer", "when lexing Rails 1.x logs" do
  
  it "should extract the Controller, action, IP, timestamp and HTTP verb from a ``Processing'' line" do
    pending "the rails log scanner"
    line = %q{Processing PageController#demo (for 127.0.0.1 at 2008-12-10 16:28:09) [GET]}
    result = line.tokenize_rails_logs
    result[:rails_teaser].first.should == "Processing"
    result[:rails_controller_action].first.should == "PageController#demo"
    result[:ipv4_addr].first.should == "127.0.0.1"
    result[:http_method].first.should == "GET"
    #result[:rails_timestamp].first.should == "2008-12-10 16:28:09"
  end
  
  it "should give a hash with :cache_hit => not falsy value for a cache hit" do
    pending("once we're using C return() with flex")
  end
  
  it "should extract an error, error_message, line of code, source code file, and stack_trace from a ``RuntimeError'' line" do
    pending "the rails log scanner"
    line = %q{RuntimeError (Cannot destroy employee):  /app/models/employee.rb:198:in `before_destroy' }
    result = line.tokenize_rails_logs
  end
  
  it "should extract the duration, view duration, db duration, HTTP status code, and url from a ``Completed'' line"

  it "should extract the duration and partial from a ``Rendered'' line"
  
  it "should skip other lines"

end
