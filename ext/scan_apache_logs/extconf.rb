require "mkmf"
$CFLAGS += " -Wall"
create_makefile "teeth/scan_apache_logs", "./"
