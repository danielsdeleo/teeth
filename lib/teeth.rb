# encoding: utf-8

TEETH_EXT_DIR = File.expand_path(File.dirname(__FILE__) + '/../ext')

require "teeth/scanner"
require "teeth/scanner_definition"
require "teeth/rule_statement"

begin
  require "teeth/scanners/scan_apache_logs"
  require "teeth/scanners/scan_rails_logs"
rescue LoadError => e
  STDERR.puts "WARNING: could not load extensions. This is okay if you are creating them from source for the first time."
end
