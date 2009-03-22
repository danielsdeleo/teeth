require File.dirname(__FILE__) + '/../spec_helper'
$INCLUDE_SLOW_TESTS = true

describe "Apache Lexer Extension", "when lexing apache errors" do

  before(:each) do
    str = "[Sun Nov 30 14:23:45 2008] [error] [client 10.0.1.197] Invalid URI in request GET .\\.\\.\\.\\.\\.\\.\\.\\.\\.\\/winnt/win.ini HTTP/1.1"
    @tokens = str.tokenize_apache_logs
  end
  
  it "should return an uuid and empty message for an empty string" do
    tokens = "".tokenize_apache_logs
    tokens[:message].should == ""
    tokens[:id].should match(/[0-9A-F]{32}/)
  end
  
  it "should extract an IP address" do
    @tokens[:ipv4_addr].first.should == "10.0.1.197"
  end
  
  it "should extract an apache datetime" do
    @tokens[:apache_err_datetime].first.should == "Sun Nov 30 14:23:45 2008"
  end
  
  it "should extract the error level" do
    @tokens[:error_level].first.should == "error"
  end
  
  it "should extract the URI" do
    @tokens[:relative_url].first.should == ".\\.\\.\\.\\.\\.\\.\\.\\.\\.\\/winnt/win.ini"
  end
  
  it "should error out if the string is longer than 1M chars" do
    str = ((("abcDE" * 2) * 1000) * 100) + "X"
    lambda {str.tokenize_apache_logs[:word]}.should raise_error(ArgumentError, "string too long for tokenize_apache_logs! max length is 1,000,000 chars")
  end
  
end

describe "Apache Lexer Extension", "when lexing apache access logs" do
  before(:each) do
    str = %q{couchdb.localdomain:80 172.16.115.1 - - [13/Dec/2008:19:26:11 -0500] "GET /favicon.ico HTTP/1.1" 404 241 "http://172.16.115.130/" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_4_11; en) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1"}
    @tokens = str.tokenize_apache_logs
    str2 = %q{127.162.219.29 - - [14/Jan/2009:15:32:32 -0500] "GET /reports//ee_commerce/paypalcart.php?toroot=http://www.shenlishi.com//skin/fxid1.txt?? HTTP/1.1" 404 5636}
    @tokens2 = str2.tokenize_apache_logs
    str3 = %q{127.81.248.53 - - [14/Jan/2009:11:49:43 -0500] "GET /reports/REPORT7_1ART02.pdf HTTP/1.1" 206 255404}
    @tokens3 = str3.tokenize_apache_logs
    str4 = %q{127.140.136.56 - - [23/Jan/2009:12:59:24 -0500] "GET /scripts/..%255c%255c../winnt/system32/cmd.exe?/c+dir" 404 5607}
    @tokens4 = str4.tokenize_apache_logs
    str5 = %q{127.254.43.205 - - [26/Jan/2009:08:32:08 -0500] "GET /reports/REPORT9_3.pdf//admin/includes/footer.php?admin_template_default=../../../../../../../../../../../../../etc/passwd%00 HTTP/1.1" 404 5673}
    @tokens5 = str5.tokenize_apache_logs
    str6 = %q{127.218.234.82 - - [26/Jan/2009:08:32:19 -0500] "GET /reports/REPORT9_3.pdf//admin/includes/header.php?bypass_installed=1&bypass_restrict=1&row_secure[account_theme]=../../../../../../../../../../../../../etc/passwd%00 HTTP/1.1" 404 5721}
    @tokens6 = str6.tokenize_apache_logs
    str_naked_url = %q{127.218.234.82 - - [26/Jan/2009:08:32:19 -0500] "GET / HTTP/1.1" 404 5721}
    @tokens_naked_url = str_naked_url.tokenize_apache_logs
  end
  
  it "provides hints for testing" do
    #puts "\n" + @tokens.inspect + "\n"
  end
  
  it "should extract the vhost name" do
    @tokens[:host].first.should == "couchdb.localdomain:80"
  end
  
  it "should extract the datetime" do
    @tokens[:apache_access_datetime].first.should == "13/Dec/2008:19:26:11 -0500"
  end
  
  it "should extract the HTTP response code" do
    @tokens[:http_response].first.should == "404"
    #(100|101|20[0-6]|30[0-5]|307|40[0-9]|41[0-7]|50[0-5])
    codes = ['100', '101'] + (200 .. 206).map { |n| n.to_s } + 
    (300 .. 305).map { |n| n.to_s } + ['307'] + (400 .. 417).map { |n| n.to_s } +
    (500 .. 505).map { |n| n.to_s }
    codes.each do |code|
      code.tokenize_apache_logs[:http_response].first.should == code
    end
  end
  
  it "should extract the HTTP version" do
    @tokens[:http_version].first.should == "HTTP/1.1"
  end
  
  it "should extract the browser string with quotes removed" do
    @tokens[:browser_string].first.should == "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_4_11; en) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1"
  end
  
  it "should not extract an HTTP code when a HTTP response code number appears in the bytes transferred" do
    #puts "\nTOKENS3:\n" + @tokens3.inspect
    @tokens3[:http_response].include?("404").should_not be_true
  end
  
  it "should correctly identify gnarly URLs from web attacks as URLs" do
    #puts "\nTOKENS2:\n" + @tokens2.inspect
    @tokens2[:relative_url].first.should == "/reports//ee_commerce/paypalcart.php?toroot=http://www.shenlishi.com//skin/fxid1.txt??"
    @tokens4[:relative_url].first.should == "/scripts/..%255c%255c../winnt/system32/cmd.exe?/c+dir"
    @tokens5[:relative_url].first.should == "/reports/REPORT9_3.pdf//admin/includes/footer.php?admin_template_default=../../../../../../../../../../../../../etc/passwd%00"
    @tokens6[:relative_url].first.should == "/reports/REPORT9_3.pdf//admin/includes/header.php?bypass_installed=1&bypass_restrict=1&row_secure[account_theme]=../../../../../../../../../../../../../etc/passwd%00"
  end
  
  it "should correctly extract ``/'' as a URL" do
    @tokens_naked_url[:relative_url].should == ["/"]
  end
  
end
