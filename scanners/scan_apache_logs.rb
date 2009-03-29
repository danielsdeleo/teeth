require File.dirname(__FILE__) + "/../lib/teeth"
scanner = Teeth::Scanner.new(:apache_logs, File.dirname(__FILE__) + '/../ext/scan_apache_logs/')
scanner.load_default_definitions_for(:whitespace, :ip, :time, :web)
scanner.rules do |r|
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