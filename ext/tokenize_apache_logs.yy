/*
 * uuid_unparse_upper_sans_dash is derived from the uuid library
 * from OS X / darwin, therefore:
 *
 * Copyright (c) 2004 Apple Computer, Inc. All rights reserved.
 *
 * %Begin-Header%
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, and the entire permission notice in its entirety,
 *    including the disclaimer of warranties.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ALL OF
 * WHICH ARE HEREBY DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF NOT ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * %End-Header%
 */

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

IP4_OCT [0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]

WDAY (Mon|Tue|Wed|Thu|Fri|Sat|Sun)

MON (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)

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
  push_token_to_hash("ipv4_addr", yytext);
}

{WDAY}{WS}{MON}{WS}{MDAY}{WS}{HOUR}\:{MINSEC}\:{MINSEC}{WS}{YEAR} {
  push_token_to_hash("apache_err_datetime", yytext);
}

{MDAY}\/{MON}\/{YEAR}\:{HOUR}\:{MINSEC}\:{MINSEC}{WS}{PLUSMINUS}{YEAR} {
  push_token_to_hash("apache_access_datetime", yytext);
}

{HTTP_VERS} { push_token_to_hash("http_version", yytext);}

{BROWSER_STR} {  push_token_to_hash("browser_string", strip_ends(yytext));}

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

{HTTP_VERB} { push_token_to_hash("http_method", yytext);}

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
VALUE t_tokenize_apache_logs(VALUE self) {
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

void Init_tokenize_apache_logs() {
  rb_define_method(rb_cString, "tokenize_apache_logs", t_tokenize_apache_logs, 0);
}
