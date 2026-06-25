use strict;
use warnings;
use v5.38.2;

my $exe_path = "E:/fpc-wasm/fpc/bin/x86_64-win64/fpc.exe";
my @args = ("-Pwasm32", "-Tembedded");
my $main_file = "main.pas";

my $exit_code = system $exe_path, @args, $main_file;

rename "main", "main.wasm" if $exit_code == 0
