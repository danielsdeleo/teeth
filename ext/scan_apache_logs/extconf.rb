require "mkmf"
$CFLAGS += " -Wall"
have_library("uuid", "uuid_generate_time")
create_makefile "teeth/scanners/scan_apache_logs", "./"
