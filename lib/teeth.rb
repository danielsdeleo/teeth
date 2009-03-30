# encoding: utf-8
begin
  require "teeth/scan_apache_logs"
  require "teeth/scan_rails_logs"
rescue LoadError => e
  STDERR.puts "WARNING: could not load extensions.  This is okay if you are creating them from\n" +
              "source for the first time.  If that isn't the case, you're screwed"
end
$:.unshift File.dirname(__FILE__) + "/"
require "scanner"
require "scanner_definition"
require "rule_statement"