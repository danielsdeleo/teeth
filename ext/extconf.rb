require 'mkmf'
$CFLAGS += " -Wall"
$LDFLAGS += " -lfl"
create_makefile "teeth/tokenize_apache_logs"