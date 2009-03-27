require File.dirname(__FILE__) + "/../spec_helper" # loads libs

error_line = %q{[Sun Nov 30 14:23:45 2008] [error] [client 10.0.1.197] Invalid URI in request GET .\\.\\.\\.\\.\\.\\.\\.\\.\\.\\/winnt/win.ini HTTP/1.1}
access_line = %q{127.81.248.53 - - [14/Jan/2009:11:49:43 -0500] "GET /reports/REPORT7_1ART02.pdf HTTP/1.1" 206 255404}

mangled_error_line = error_line + "more words"

puts "Processed Error Message:"
puts error_line.tokenize_apache_logs.inspect
puts "Error Message with extras:"
puts mangled_error_line.tokenize_apache_logs.inspect
puts "Processed Access Message"
puts access_line.tokenize_apache_logs.inspect