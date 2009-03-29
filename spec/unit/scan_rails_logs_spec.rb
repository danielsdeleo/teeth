require File.dirname(__FILE__) + '/../spec_helper'
require "teeth/scan_rails_logs"
# special shout out to Willem van Bergen, author of request-log-analyzer:
# http://github.com/wvanbergen/request-log-analyzer/
# Stole the rails request logs from there...

describe "Rails Request Log Lexer", "when lexing Rails 1.x logs" do
  
  it "should extract the Controller, action, IP, timestamp and HTTP verb from a ``Processing'' line" do
    line = %q{Processing PageController#demo (for 127.0.0.1 at 2008-12-10 16:28:09) [GET]}
    result = line.scan_rails_logs
    result[:teaser].first.should == "Processing"
    result[:controller_action].first.should == "PageController#demo"
    result[:ipv4_addr].first.should == "127.0.0.1"
    result[:http_method].first.should == "GET"
    result[:datetime].first.should == "2008-12-10 16:28:09"
  end
  
  it "should give a hash with :cache_hit => not falsy value for a cache hit" do
    cache_hit = %q{Filter chain halted as [#<ActionController::Caching::Actions::ActionCacheFilter:0x2a999ad620 @check=nil, @options={:store_options=>{}, :layout=>nil, :cache_path=>#<Proc:0x0000002a999b8890@/app/controllers/cached_controller.rb:8>}>] rendered_or_redirected.}
    cache_hit.scan_rails_logs[:cache_hit].should be_true
    cache_hit.scan_rails_logs[:teaser].first.should == "Filter chain halted"
  end
  
  it "should extract an error, error_message, line of code, source code file, and stack_trace from a ``RuntimeError'' line" do
    line = %q{RuntimeError (Cannot destroy employee):  /app/models/employee.rb:198:in `before_destroy' }
    result = line.scan_rails_logs
    puts "###\n" + result.inspect
    result[:error].first.should == "RuntimeError"
    result[:error_message].first.should == "Cannot destroy employee"
    result[:file_and_line].first.should == "/app/models/employee.rb:198"
  end
  
  it "should extract the duration, view duration, db duration, HTTP status code, and url from a ``Completed'' line for Rails 1.x" do
    rails_1x = %q{Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]}
    pending("once generated scanner supports start conditions/BEGIN")
    result = rails_1x.scan_rails_logs
    result[:teaser].first.should == "Completed in"
    result[:duration_s].first.should == "0.21665"
    result[:rendering_duration_s].first.should == "0.00926"
    result[:db_duration_s].first.should == "0.00000"
    result[:http_response].first.should == "200"
    result[:url].first.should == "http://demo.nu/employees"
  end
  
  it "should extract the relevant components from a ``Completed'' line for Rails 2.x" do
    rails_2x =  %q{Completed in 614ms (View: 120, DB: 31) | 200 OK [http://floorplanner.local/demo]}
    pending("once generated scanner supports start conditions/BEGIN")
  end

  it "should extract the duration and partial from a ``Rendered'' line for rails 2.x" do
    rendered_2x = "Rendered shared/_analytics (0.2ms)"
    puts "(rendered 2.x): " + rendered_2x.scan_rails_logs.inspect
    rendered_2x.scan_rails_logs[:partial].first.should == "shared/_analytics"
    rendered_2x.scan_rails_logs[:render_duration_ms].first.should == "0.2"
  end
  
  it "should extract the duration and partial from a ``Rendered'' line for rails 1.x" do
    rendered_1x = "Rendered layouts/_doc_type (0.00001)"
    puts "(rendered 1.x): " + rendered_1x.scan_rails_logs.inspect
    rendered_1x.scan_rails_logs[:partial].first.should == "layouts/_doc_type"
    rendered_1x.scan_rails_logs[:render_duration_s].first.should == "0.00001"
  end
  
  it "should skip session id lines" do
    session_id = %q{Session ID: BAh7CToMcmVmZXJlciIbL3ByaXNjaWxsYS9wZW9wbGUvMjM1MCIKZmxhc2hJ}
    session_id.scan_rails_logs.keys.map { |k| k.to_s}.sort.should == ["id", "message"]
  end
  
  it "should not return a teaser for session id continuation lines" do
    session_id_contd = "ZWR7ADoNbGFuZ3VhZ2VvOhNMb2NhbGU6Ok9iamVjdBI6CUB3aW4wOg1AY291"
    puts session_id_contd.scan_rails_logs[:teaser].should be_nil
  end
  
  it "should give a non falsy value for :end_session_id at for the last line of a session id" do
    session_id_end_1 = "bmxfTkw6DEBzY3JpcHQwOg5AZmFsbGJhY2sw--48cbe3788ef27f6005f8e999610a42af6e90ffb3"
    session_id_end_1.scan_rails_logs[:end_session_id].should_not be_nil
    session_id_end_2 = "X2lkaQIyBw==--3ad1948559448522a49d289a2a89dc7ccbe8847a"
    session_id_end_2.scan_rails_logs[:end_session_id].should_not be_nil
  end
  

end
