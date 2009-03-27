/* %option prefix="vor_yy" */
%option full
%option never-interactive
%option read
%option nounput
%{
#include <ruby.h>
#include <uuid/uuid.h>
/* Data types */
typedef struct {
  char *key;
  char *value;
} KVPAIR;
/* Globals (eww, globals!) */
static KVPAIR EOF_KVPAIR = {"EOF", "EOF"};
/* prototypes */
char *strip_ends(char *);
VALUE t_tokenize_apache_logs(VALUE);
void new_uuid(char *str_ptr);
void raise_error_for_string_too_long(VALUE string);
void include_message_in_token_hash(VALUE message, VALUE token_hash);
void add_uuid_to_token_hash(VALUE token_hash);
void push_kv_pair_to_hash(KVPAIR key_value, VALUE token_hash);
void concat_word_to_string(KVPAIR key_value, VALUE token_hash);
/* Set the scanner name, and return type */
#define YY_DECL KVPAIR flexscan(void)
#define yyterminate() return EOF_KVPAIR
%}

/* Definitions */

IP4_OCT [0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]

WDAY mon|tue|wed|thu|fri|sat|sun

MON jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec

MDAY 3[0-1]|[1-2][0-9]|0[1-9]

HOUR 2[0-3]|[0-1][0-9]

MINSEC [0-5][0-9]|60

YEAR [0-9][0-9][0-9][0-9]

REL_URL (\/|\\|\.)[a-z0-9\._\~\-\/\?&;#=\%\:\+\[\]\\]*

PROTO (http:|https:)

HOST [a-z0-9][a-z0-9\-]*\.[a-z0-9][a-z0-9\-]*.[a-z0-9][a-z0-9\-\.]*[a-z]+(\:[0-9]+)?

ERR_LVL (emerg|alert|crit|err|error|warn|warning|notice|info|debug)

PLUSMINUS (\+|\-)

HTTP_VERS HTTP\/(1.0|1.1)

HTTP_VERB (get|head|put|post|delete|trace|connect)

HTTPCODE (100|101|20[0-6]|30[0-5]|307|40[0-9]|41[0-7]|50[0-5])

WS  [\000-\s]

/* 
Covers most of the bases, but there are a F*-ton of these: http://www.zytrax.com/tech/web/browser_ids.htm 
Also, handling of quotes is nieve. If it becomes a problem try something like 
http://flex.sourceforge.net/manual/How-can-I-match-C_002dstyle-comments_003f.html#How-can-I-match-C_002dstyle-comments_003f
*/
BROWSER_STR \"(moz|msie|lynx).+\"

NON_WS ([a-z]|[0-9]|[:punct:])

%%
  /* 
    Actions 
 */
  
{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}  {
  KVPAIR ipv4_addr = {"ipv4_addr", yytext};
  return ipv4_addr;
}

{WDAY}{WS}{MON}{WS}{MDAY}{WS}{HOUR}":"{MINSEC}":"{MINSEC}{WS}{YEAR} {
  KVPAIR apache_err_datetime = { "apache_err_datetime", yytext};
  return apache_err_datetime;
}

{MDAY}\/{MON}\/{YEAR}":"{HOUR}":"{MINSEC}":"{MINSEC}{WS}{PLUSMINUS}{YEAR} {
  KVPAIR apache_access_datetime = {"apache_access_datetime", yytext};
  return apache_access_datetime;
}

{HTTP_VERS} { 
  KVPAIR http_version = {"http_version", yytext};
  return http_version;
}

{BROWSER_STR} {
  KVPAIR browser_string = {"browser_string", strip_ends(yytext)};
  return browser_string;
}

{PROTO}"\/\/"({HOST}|{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT})({REL_URL}|"\/")? {
  KVPAIR absolute_url = {"absolute_url", yytext};
  return absolute_url;
}

{HOST} {
  KVPAIR host = {"host", yytext};
  return host;
}

{REL_URL}   {
  KVPAIR relative_url = {"relative_url", yytext};
  return relative_url;
}

{ERR_LVL} {
  KVPAIR error_level = {"error_level", yytext};
  return error_level;
}

{HTTPCODE} {
  KVPAIR http_response = {"http_response", yytext};
  return http_response;
}

{HTTP_VERB} {
  KVPAIR http_method = {"http_method", yytext};
  return http_method;
}

{NON_WS}{NON_WS}*   {
  KVPAIR word = {"strings", yytext};
  return word;
}

(.|"\n") /* ignore */
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
  if( strlen(RSTRING(string)->ptr) > 1000000){
    rb_raise(rb_eArgError, "string too long for tokenize_apache_logs! max length is 1,000,000 chars"); 
  }
}

/* Processes a line from an Apache log file (error or access log) and returns a
 * Hash of the form {:token_type => ["value1", "value2"...] ...}
 * The types of tokens extracted are IPv4 addresses, HTTP verbs, response codes
 * and version strings, hostnames, relative and absolute URIs, browser strings,
 * error levels, and other words */
VALUE t_tokenize_apache_logs(VALUE self) {
  KVPAIR kv_result;
  int scan_complete = 0;
  int building_words_to_string = 0;
  VALUE token_hash = rb_hash_new();

  /* error out on absurdly large strings */
  raise_error_for_string_too_long(self);
  /* {:message => self()} */
  include_message_in_token_hash(self, token_hash);
  /* {:id => UUID} */
  add_uuid_to_token_hash(token_hash);
  yy_scan_string(RSTRING(self)->ptr);
  while (scan_complete == 0) {
    kv_result = flexscan();
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
   default:
      /* raise exception */
      rb_raise(rb_eTypeError, "expecting member of hash to be nil or array");
      break;
  }
}

void Init_tokenize_apache_logs() {
  rb_define_method(rb_cString, "tokenize_apache_logs", t_tokenize_apache_logs, 0);
}
