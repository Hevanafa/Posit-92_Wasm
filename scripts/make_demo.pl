# Copied from make.pl, only a different unit path

use strict;
use warnings;
use v5.38.2;

my $compiler_path = "E:/fpc-wasm/fpc/bin/x86_64-win64/fpc.exe";
my $primary_unit = "game.lpr";
my $output_file = "game.wasm";

my @args = (
  "-Pwasm32",
  "-Tembedded",
  "-Fu../../experimental/units",
  "-dWASM",
  "-o$output_file",
  $primary_unit
);

my $exit_code = system $compiler_path, @args;

if ($exit_code != 0) {
  say "Compilation failed with exit code $exit_code";
  exit $exit_code
}
