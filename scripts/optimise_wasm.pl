use strict;
use warnings;
use v5.38.2;

use POSIX qw(ceil);

my $wasm_opt_path = "E:/binaryen/bin/wasm-opt.exe";
my $wasm_file = "game.wasm";
my $output_file = "game.wasm";

unless (-e $wasm_opt_path) {
  say "Couldn't find wasm-opt at ".$wasm_opt_path;
  exit 1
}

unless (-e $wasm_file) {
  say "Missing $wasm_file!";
  exit 1
}

my $original_size = -s $wasm_file;

my @args = (
  $wasm_file,
  "-o",
  $output_file,
  "-Oz",
  "--strip-debug",
  "--enable-bulk-memory"
);

system $wasm_opt_path, @args;

if ($? != -1) {
  my $new_size = -s $output_file;

  say "Optimised $wasm_file successfully";
  # say "Size: " . $original_size . " --> " . $new_size
  printf "Size: %d (%d KB) --> %d (%d KB)", $original_size, ceil($original_size / 1024), $new_size, ceil($new_size / 1024)
} else {
  say "Failed to optimise."
}