/* %option prefix="vor_yy" */
%option full
%{
#include <ruby.h>
#include <uuid/uuid.h>

/* prototypes */
static VALUE vor_curr_tok_hsh;
char *strip_ends(char *);
void push_token_to_hash(char *, char *);
VALUE t_tokenize_apache_logs(VALUE);
void new_uuid(char *str_ptr);
%}
/* Definitions */

RAILS_TEASER (processing|session|parameters|set[\000-\s]language[\000-\s]to|redirected|rendered|completed)

CONTROLLER_ACTION [a-z]+#[a-z]+

IP4_OCT [0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]

WDAY (Mon|Tue|Wed|Thu|Fri|Sat|Sun)

MON (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)

MON_NUM (0[1-9]|1[0-2])

MDAY (3[0-1]|[1-2][0-9]|0[1-9])

HOUR (2[0-3]|[0-1][0-9])

MINSEC [0-5][0-9]

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

NON_WS ([a-z]|[0-9]|[:punct:])

%%
  /* 
    Actions 
 */

{RAILS_TEASER} {
  push_token_to_hash("rails_teaser", yytext);
}

{CONTROLLER_ACTION} {
  push_token_to_hash("rails_controller_action", yytext);
}
  
{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}  {
  push_token_to_hash("ipv4_addr", yytext);
}

{YEAR}\-{MON_NUM}\-{MDAY}{WS}{HOUR}\:{MINSEC}\:{MINSEC} {
  push_token_to_hash("rails_datetime", yytext);
}

{WDAY}{WS}{MON}{WS}{MDAY}{WS}{HOUR}\:{MINSEC}\:{MINSEC}{WS}{YEAR} {
  push_token_to_hash("apache_err_datetime", yytext);
}

{MDAY}\/{MON}\/{YEAR}\:{HOUR}\:{MINSEC}\:{MINSEC}{WS}{PLUSMINUS}{YEAR} {
  push_token_to_hash("apache_access_datetime", yytext);
}

{HTTP_VERS} { push_token_to_hash("http_version", yytext);}

{PROTO}"\/\/"({HOST}|{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT}"."{IP4_OCT})({REL_URL}|"\/")? {
  push_token_to_hash("absolute_url", yytext);
}

{HOST} {push_token_to_hash("host", yytext);}

{REL_URL}   {
  push_token_to_hash("relative_url", yytext);
}

{ERR_LVL} {
  push_token_to_hash("error_level", yytext);
}

{HTTPCODE} { push_token_to_hash("http_response", yytext); }

\[{HTTP_VERB}\] { push_token_to_hash("http_method", strip_ends(yytext));}

{NON_WS}{NON_WS}*   {
  push_token_to_hash("word", yytext);
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

/* Processes a line from an Apache log file (error or access log) and returns a
 * Hash of the form {:token_type => ["value1", "value2"...] ...}
 * The types of tokens extracted are IPv4 addresses, HTTP verbs, response codes
 * and version strings, hostnames, relative and absolute URIs, browser strings,
 * error levels, and other words */
VALUE t_tokenize_rails_logs(VALUE self) {
  char new_uuid_str[33];
  vor_curr_tok_hsh = rb_hash_new();
  rb_global_variable(&vor_curr_tok_hsh);
  /* error out on absurdly large strings */
  if( RSTRING_LEN(self) > 1000000){
    rb_raise(rb_eArgError, "string too long for tokenize_apache_logs! max length is 1,000,000 chars");
  }
  else{
    /* {:message => self} */
    VALUE hsh_key_msg = ID2SYM(rb_intern("message"));
    rb_hash_aset(vor_curr_tok_hsh, hsh_key_msg, self);
    /* {:id => generated_uuid} */
    new_uuid(new_uuid_str);
    VALUE hsh_key_id = ID2SYM(rb_intern("id"));
    VALUE hsh_val_id = rb_tainted_str_new2(new_uuid_str);
    rb_hash_aset(vor_curr_tok_hsh, hsh_key_id, hsh_val_id);
    yy_scan_string(RSTRING_PTR(self));
    yylex();
    yy_delete_buffer(YY_CURRENT_BUFFER);
  }
  return rb_obj_dup(vor_curr_tok_hsh);
}

void push_token_to_hash(char * token_type, char * token_val) {
  VALUE hsh_key = ID2SYM(rb_intern(token_type));
  VALUE hsh_value = rb_hash_aref(vor_curr_tok_hsh, hsh_key);
  VALUE ary_for_token_type = rb_ary_new();
  switch (TYPE(hsh_value)) {
    case T_NIL:
      rb_ary_push(ary_for_token_type, rb_tainted_str_new2(token_val));
      rb_hash_aset(vor_curr_tok_hsh, hsh_key, ary_for_token_type);
      break;
    case T_ARRAY:
      rb_ary_push(hsh_value, rb_tainted_str_new2(token_val));
      break;
   default:
      /* raise exception */
      rb_raise(rb_eTypeError, "expecting member of hash to be nil or array");
      break;
  }
}

void Init_tokenize_rails_logs() {
  rb_define_method(rb_cString, "tokenize_rails_logs", t_tokenize_rails_logs, 0);
}