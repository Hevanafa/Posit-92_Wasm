use strict;
use warnings;
use v5.38.2;

my $wasm_opt_path = "E:/binaryen/bin/wasm-opt.exe";
my $wasm_file = "game.wasm";
my $output_file = "game_optimised.wasm";

unless (-e $wasm_opt_path) {
  say "Couldn't find wasm-opt at ".$wasm_opt_path;
  exit 1
}

unless (-e $wasm_file) {
  say "Missing $wasm_file!";
  exit 1
}

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
  say "Optimised $wasm_file successfully"
} else {
  say "Failed to optimise."
}