%option prefix="rails_logs_yy"
%option full
%option never-interactive
%option read
%option nounput
%option noyywrap noreject noyymore nodefault
%{
#include <ruby.h>
#include <uuid/uuid.h>
/* Data types */
typedef struct {
  char *key;
  char *value;
} KVPAIR;
const KVPAIR EOF_KVPAIR = {"EOF", "EOF"};
/* prototypes */
char *strip_ends(char *);
VALUE t_scan_rails_logs(VALUE);
void new_uuid(char *str_ptr);
void raise_error_for_string_too_long(VALUE string);
void include_message_in_token_hash(VALUE message, VALUE token_hash);
void add_uuid_to_token_hash(VALUE token_hash);
void push_kv_pair_to_hash(KVPAIR key_value, VALUE token_hash);
void concat_word_to_string(KVPAIR key_value, VALUE token_hash);
/* Set the scanner name, and return type */
#define YY_DECL KVPAIR scan_rails_logs(void)
#define yyterminate() return EOF_KVPAIR
/* Ruby 1.8 and 1.9 compatibility */
#if !defined(RSTRING_LEN) 
# define RSTRING_LEN(x) (RSTRING(x)->len) 
# define RSTRING_PTR(x) (RSTRING(x)->ptr) 
#endif 

%}

/* Definitions */

CATCHALL (.|"\n")


WS [[:space:]]

NON_WS ([a-z]|[0-9]|[:punct:])

IP4_OCT [0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]

HOST [a-z0-9][a-z0-9\-]*\.[a-z0-9][a-z0-9\-]*.[a-z0-9][a-z0-9\-\.]*[a-z]+(\:[0-9]+)?

WDAY mon|tue|wed|thu|fri|sat|sun

MON jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec

MONTH_NUM 0[1-9]|1[0-2]

MDAY 3[0-1]|[1-2][0-9]|0[1-9]

HOUR 2[0-3]|[0-1][0-9]

MINSEC [0-5][0-9]|60

YEAR [0-9][0-9][0-9][0-9]

PLUSMINUS (\+|\-)

REL_URL (\/|\\|\.)[a-z0-9\._\~\-\/\?&;#=\%\:\+\[\]\\]*

PROTO (http:|https:)

ERR_LVL (emerg|alert|crit|err|error|warn|warning|notice|info|debug)

HTTP_VERS HTTP\/(1.0|1.1)

HTTP_VERB (get|head|put|post|delete|trace|connect)

HTTPCODE (100|101|20[0-6]|30[0-5]|307|40[0-9]|41[0-7]|50[0-5])

BROWSER_STR \"(moz|msie|lynx).+\"

RAILS_TEASER (processing|filter\ chain\ halted|rendered)

CONTROLLER_ACTION [a-z0-9]+#[a-z0-9]+

RAILS_SKIP_LINES (session\ id)

CACHE_HIT actioncontroller"::"caching"::"actions"::"actioncachefilter":"0x[0-9a-f]+

PARTIAL_SESSION_ID ^([a-z0-9]+"="*"-"+[a-z0-9]+)

RAILS_ERROR_CLASS ([a-z]+\:\:)*[a-z]+error

%x REQUEST_COMPLETED

%x COMPLETED_REQ_VIEW_STATS

%x COMPLETED_REQ_DB_STATS


%%
  /* 
    Actions 
 */
  

{RAILS_TEASER} {
  KVPAIR teaser = {"teaser", yytext};
  return teaser;
}

{CONTROLLER_ACTION} {
  KVPAIR controller_action = {"controller_action", yytext};
  return controller_action;
}

{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT} {
  KVPAIR ipv4_addr = {"ipv4_addr", yytext};
  return ipv4_addr;
}

{YEAR}"-"{MONTH_NUM}"-"{MDAY}{WS}{HOUR}":"{MINSEC}":"{MINSEC} {
  KVPAIR datetime = {"datetime", yytext};
  return datetime;
}

{HTTP_VERB} {
  KVPAIR http_method = {"http_method", yytext};
  return http_method;
}

{RAILS_SKIP_LINES} {
  return EOF_KVPAIR;
}

{PARTIAL_SESSION_ID} {
  KVPAIR end_session_id = {"end_session_id", yytext};
  return end_session_id;
}

{RAILS_ERROR_CLASS} {
  KVPAIR error = {"error", yytext};
  return error;
}

\(({WS}|{NON_WS})+\) {
  KVPAIR error_message = {"error_message", strip_ends(yytext)};
  return error_message;
}

"#"[0-9]+{WS} {
  KVPAIR line_number = {"line_number", strip_ends(yytext)};
  return line_number;
}

{WS}{REL_URL}":" {
  KVPAIR file_and_line = {"file_and_line", strip_ends(yytext)};
  return file_and_line;
}

{CACHE_HIT} {
  KVPAIR cache_hit = {"cache_hit", yytext};
  return cache_hit;
}

[a-z0-9]+{REL_URL}/\ \( {
  KVPAIR partial = {"partial", yytext};
  return partial;
}

[0-9\.]+/ms\) {
  KVPAIR render_duration_ms = {"render_duration_ms", yytext};
  return render_duration_ms;
}

\([0-9\.]+\) {
  KVPAIR render_duration_s = {"render_duration_s", strip_ends(yytext)};
  return render_duration_s;
}

completed\ in {
  BEGIN(REQUEST_COMPLETED);
  KVPAIR teaser = {"teaser", yytext};
  return teaser;
}

<REQUEST_COMPLETED>[0-9]+\.[0-9]+ {
  KVPAIR duration_s = {"duration_s", yytext};
  return duration_s;
}

<REQUEST_COMPLETED>[0-9]+/ms {
  KVPAIR duration_ms = {"duration_ms", yytext};
  return duration_ms;
}

<REQUEST_COMPLETED>(View":"|Rendering":") {
  BEGIN(COMPLETED_REQ_VIEW_STATS);
  KVPAIR start_view_stats = {"start_view_stats", yytext};
  return start_view_stats;
}

<COMPLETED_REQ_VIEW_STATS>([0-9]+\.[0-9]+) {
  BEGIN(REQUEST_COMPLETED);
  KVPAIR view_s = {"view_s", yytext};
  return view_s;
}

<COMPLETED_REQ_VIEW_STATS>[0-9]+ {
  BEGIN(REQUEST_COMPLETED);
  KVPAIR view_ms = {"view_ms", yytext};
  return view_ms;
}

<COMPLETED_REQ_VIEW_STATS>{CATCHALL}

<REQUEST_COMPLETED>DB":" {
  BEGIN(COMPLETED_REQ_DB_STATS);
  KVPAIR start_db_stats = {"start_db_stats", yytext};
  return start_db_stats;
}

<COMPLETED_REQ_DB_STATS>[0-9]+\.[0-9]+ {
  BEGIN(REQUEST_COMPLETED);
  KVPAIR db_s = {"db_s", yytext};
  return db_s;
}

<COMPLETED_REQ_DB_STATS>[0-9]+ {
  BEGIN(REQUEST_COMPLETED);
  KVPAIR db_ms = {"db_ms", yytext};
  return db_ms;
}

<COMPLETED_REQ_DB_STATS>{CATCHALL}

<REQUEST_COMPLETED>\[{PROTO}"\/\/"({HOST}|{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT})({REL_URL}|"\/")?\] {
  KVPAIR url = {"url", strip_ends(yytext)};
  return url;
}

<REQUEST_COMPLETED>{HTTPCODE} {
  KVPAIR http_response = {"http_response", yytext};
  return http_response;
}

<REQUEST_COMPLETED>{NON_WS}{NON_WS}* {
  KVPAIR strings = {"strings", yytext};
  return strings;
}

<REQUEST_COMPLETED>{CATCHALL}

{NON_WS}{NON_WS}* {
  KVPAIR strings = {"strings", yytext};
  return strings;
}

{CATCHALL} /* ignore */
%%

char *strip_ends(char *string) {
  string[yyleng-1] = '\0';
  ++string;
  return string;
}

void uuid_unparse_upper_sans_dash(const uuid_t uu, char *out)
{
        sprintf(out,
                "%02X%02X%02X%02X"
                "%02X%02X"
                "%02X%02X"
                "%02X%02X"
                "%02X%02X%02X%02X%02X%02X",
                uu[0], uu[1], uu[2], uu[3],
                uu[4], uu[5],
                uu[6], uu[7],
                uu[8], uu[9],
                uu[10], uu[11], uu[12], uu[13], uu[14], uu[15]);
}

void new_uuid(char *str_ptr){
  uuid_t new_uuid;
  uuid_generate_time(new_uuid);
  uuid_unparse_upper_sans_dash(new_uuid, str_ptr);
}

void raise_error_for_string_too_long(VALUE string){
  if( RSTRING_LEN(string) > 1000000){
    rb_raise(rb_eArgError, "string too long for scan_rails_logs! max length is 1,000,000 chars"); 
  }
}


VALUE t_scan_rails_logs(VALUE self) {
  KVPAIR kv_result;
  int scan_complete = 0;
  int building_words_to_string = 0;
  VALUE token_hash = rb_hash_new();
  
  BEGIN(INITIAL);
  
  /* error out on absurdly large strings */
  raise_error_for_string_too_long(self);
  /* {:message => self()} */
  include_message_in_token_hash(self, token_hash);
  /* {:id => UUID} */
  add_uuid_to_token_hash(token_hash);
  yy_scan_string(RSTRING_PTR(self));
  while (scan_complete == 0) {
    kv_result = scan_rails_logs();
    if (kv_result.key == "EOF"){
      scan_complete = 1;
    }
    else if (kv_result.key == "strings"){
      /* build a string until we get a non-word */
      if (building_words_to_string == 0){
        building_words_to_string = 1;
        push_kv_pair_to_hash(kv_result, token_hash);
      }
      else{
        concat_word_to_string(kv_result, token_hash);
      }    
    }    
    else {
      building_words_to_string = 0;
      push_kv_pair_to_hash(kv_result, token_hash);
    }
  }
  yy_delete_buffer(YY_CURRENT_BUFFER);
  return rb_obj_dup(token_hash);
}

void add_uuid_to_token_hash(VALUE token_hash) {
  char new_uuid_str[33];
  new_uuid(new_uuid_str);
  VALUE hsh_key_id = ID2SYM(rb_intern("id"));
  VALUE hsh_val_id = rb_tainted_str_new2(new_uuid_str);
  rb_hash_aset(token_hash, hsh_key_id, hsh_val_id);
}

void include_message_in_token_hash(VALUE message, VALUE token_hash) {
  /* {:message => self()} */  
  VALUE hsh_key_msg = ID2SYM(rb_intern("message"));
  rb_hash_aset(token_hash, hsh_key_msg, message);
}

void concat_word_to_string(KVPAIR key_value, VALUE token_hash) {
  char * space = " ";
  VALUE hsh_key = ID2SYM(rb_intern(key_value.key));
  VALUE hsh_value = rb_hash_aref(token_hash, hsh_key);
  VALUE string = rb_ary_entry(hsh_value, -1);
  rb_str_cat(string, space, 1);
  rb_str_cat(string, key_value.value, yyleng);
}

void push_kv_pair_to_hash(KVPAIR key_value, VALUE token_hash) {
  VALUE hsh_key = ID2SYM(rb_intern(key_value.key));
  VALUE hsh_value = rb_hash_aref(token_hash, hsh_key);
  VALUE ary_for_token_type = rb_ary_new();
  switch (TYPE(hsh_value)) {
    case T_NIL:
      rb_ary_push(ary_for_token_type, rb_tainted_str_new2(key_value.value));
      rb_hash_aset(token_hash, hsh_key, ary_for_token_type);
      break;
    case T_ARRAY:
      rb_ary_push(hsh_value, rb_tainted_str_new2(key_value.value));
      break;
  }
}

void Init_scan_rails_logs() {
  rb_define_method(rb_cString, "scan_rails_logs", t_scan_rails_logs, 0);
}
