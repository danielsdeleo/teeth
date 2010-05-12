require File.expand_path(File.dirname(__FILE__) + "/../lib/teeth")
scanner = Teeth::Scanner.new(:rails_logs, File.dirname(__FILE__) + '/../ext/scan_rails_logs/')
scanner.load_default_definitions_for(:whitespace, :ip, :time, :web)
scanner.rdoc = <<-RDOC
Scans self, which is expected to be a line from a Rails production or dev log,
and returns a Hash of the significant features in the log message, including 
the IP address of the client, the Controller and Action, any partials rendered,
and the time spent rendering them, the duration of the DB request(s), the HTTP
verb, etc.
RDOC
scanner.definitions do |define|
  define.RAILS_TEASER '(processing|filter\ chain\ halted|rendered)'
  define.CONTROLLER_ACTION '[a-z0-9]+#[a-z0-9]+'
  define.RAILS_SKIP_LINES '(session\ id)'
  define.CACHE_HIT 'actioncontroller"::"caching"::"actions"::"actioncachefilter":"0x[0-9a-f]+'
  define.PARTIAL_SESSION_ID '^([a-z0-9]+"="*"-"+[a-z0-9]+)'
  define.RAILS_ERROR_CLASS '([a-z]+\:\:)*[a-z]+error'
  define.REQUEST_COMPLETED :start_condition => :exclusive
  define.COMPLETED_REQ_VIEW_STATS :start_condition => :exclusive
  define.COMPLETED_REQ_DB_STATS :start_condition => :exclusive
end
scanner.rules do |r|
  # Processing DashboardController#index (for 1.1.1.1 at 2008-08-14 21:16:25) [GET]
  r.teaser '{RAILS_TEASER}'
  r.controller_action '{CONTROLLER_ACTION}'
  r.ipv4_addr '{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}'
  r.datetime '{YEAR}"-"{MONTH_NUM}"-"{MDAY}{WS}{HOUR}":"{MINSEC}":"{MINSEC}'
  r.http_method '{HTTP_VERB}'
  # Session ID: BAh7CToMcmVmZXJlciIbL3ByaXNjaWxsYS9wZW9wbGUvMjM1MCIKZmxhc2hJ
  # QzonQWN0aW9uQ29udHJvbGxlcjo6Rmxhc2g6OkZsYXNoSGFzaHsABjoKQHVz ...
  r.skip_lines '{RAILS_SKIP_LINES}', :skip_line => true
  r.end_session_id '{PARTIAL_SESSION_ID}'
  # RuntimeError (Cannot destroy employee):  /app/models/employee.rb:198:in `before_destroy' 
  # ActionController::RoutingError (no route found to match "/favicon.ico" with {:method=>:get}):
  # ActionView::TemplateError (No rhtml, rxml, rjs or delegate template found for /shared/_ids_modal_selection_panel in script/../config/../app/views) on line #2 of app/views/events/index.rhtml:
  # ActionView::TemplateError (You have a nil object when you didn't expect it!
  # NoMethodError (undefined method `find' for ActionController::Filters::Filter:Class):
  r.error '{RAILS_ERROR_CLASS}'
  r.error_message '\(({WS}|{NON_WS})+\)', :strip_ends => true
  r.line_number '"#"[0-9]+{WS}', :strip_ends => true
  r.file_and_line '{WS}{REL_URL}":"', :strip_ends => true
  # Filter chain halted as [#<ActionController::Caching::Actions::ActionCacheFilter:0x2a999ad620 @check=nil, @options={:store_options=>{}, :layout=>nil, :cache_path=>#<Proc:0x0000002a999b8890@/app/controllers/cached_controller.rb:8>}>] rendered_or_redirected.    
  r.cache_hit '{CACHE_HIT}'
  # Rendered shared/_analytics (0.2ms)
  # Rendered layouts/_doc_type (0.00001)
  r.partial '[a-z0-9]+{REL_URL}/\ \('
  r.render_duration_ms '[0-9\.]+/ms\)'
  r.render_duration_s '\([0-9\.]+\)', :strip_ends => true
  # Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]
  # Completed in 614ms (View: 120, DB: 31) | 200 OK [http://floorplanner.local/demo]
  r.teaser 'completed\ in', :begin => "REQUEST_COMPLETED"
  r.duration_s '<REQUEST_COMPLETED>[0-9]+\.[0-9]+'
  r.duration_ms '<REQUEST_COMPLETED>[0-9]+/ms'
  r.start_view_stats '<REQUEST_COMPLETED>(View":"|Rendering":")', :begin => "COMPLETED_REQ_VIEW_STATS"
  r.view_s '<COMPLETED_REQ_VIEW_STATS>([0-9]+\.[0-9]+)', :begin => "REQUEST_COMPLETED"
  r.view_ms '<COMPLETED_REQ_VIEW_STATS>[0-9]+', :begin => "REQUEST_COMPLETED"
  r.view_throwaway_tokens '<COMPLETED_REQ_VIEW_STATS>{CATCHALL}', :ignore => true
  r.start_db_stats '<REQUEST_COMPLETED>DB":"', :begin => "COMPLETED_REQ_DB_STATS"
  r.db_s '<COMPLETED_REQ_DB_STATS>[0-9]+\.[0-9]+', :begin => "REQUEST_COMPLETED"
  r.db_ms '<COMPLETED_REQ_DB_STATS>[0-9]+', :begin => "REQUEST_COMPLETED"
  r.db_throwaway_tokens '<COMPLETED_REQ_DB_STATS>{CATCHALL}', :ignore => true
  r.url '<REQUEST_COMPLETED>\[{PROTO}"\/\/"({HOST}|({IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}))({REL_URL}|"/"|"\\\\")?\]', :strip_ends => true
  r.http_response '<REQUEST_COMPLETED>{HTTPCODE}'
  r.strings '<REQUEST_COMPLETED>{NON_WS}{NON_WS}*'
  r.ignore_others '<REQUEST_COMPLETED>{CATCHALL}', :ignore => true
  # fallback to collecting strings
  r.strings '{NON_WS}{NON_WS}*'
end

scanner.write!