require "teeth"
scanner = Teeth::Scanner.new(:apache_logs, TEETH_EXT_DIR + '/scan_apache_logs/')
scanner.load_default_definitions_for(:whitespace, :ip, :time, :web)
scanner.rdoc = <<-RDOC
Scans self, which is expected to be a single line from an Apache error or 
access log, and returns a Hash of the components of the log message.  The
following parts of the log message are returned if they are present:
IPv4 address, datetime, HTTP Version used, the browser string given by the 
client, any absolute or relative URLs, the error level, HTTP response code,
HTTP Method (verb), and any other uncategorized strings present.
RDOC
scanner.rules do |r|
  r.timing '{TIMING}'
  r.ipv4_addr '{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}'
  r.apache_err_datetime '{WDAY}{WS}{MON}{WS}{MDAY}{WS}{HOUR}":"{MINSEC}":"{MINSEC}{WS}{YEAR}'
  r.apache_access_datetime '{MDAY}\/{MON}\/{YEAR}":"{HOUR}":"{MINSEC}":"{MINSEC}{WS}{PLUSMINUS}{YEAR}'
  r.http_version '{HTTP_VERS}'
  r.browser_string '{BROWSER_STR}', :strip_ends => true
  r.absolute_url '{PROTO}"\/\/"({HOST}|{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT})({REL_URL}|"\/")?'
  r.host '{HOST}'
  r.relative_url '{REL_URL}'
  r.error_level '{ERR_LVL}'
  r.http_response '{HTTPCODE}'
  r.http_method '{HTTP_VERB}'
  r.strings '{NON_WS}{NON_WS}*'
end

scanner.write!