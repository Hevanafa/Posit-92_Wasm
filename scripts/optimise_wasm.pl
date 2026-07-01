use strict;
use warnings;
use v5.38.2;

use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

use POSIX qw(ceil);

my $script_dir = $Bin;
my $wasm_opt_path = "E:/binaryen/bin/wasm-opt.exe";

my $game_wasm = "game.wasm";
my $output_file = "game_optimised.wasm";

my $wasm_path = catfile($script_dir, $game_wasm);
my $output_path = catfile($script_dir, $output_file);

unless (-e $wasm_opt_path) {
  say "Couldn't find wasm-opt at ".$wasm_opt_path;
  exit 1
}

unless (-e $wasm_path) {
  say "Missing $wasm_path!";
  exit 1
}

my $original_size = -s $wasm_path;

my @args = (
  $wasm_path,
  "-o",
  $output_path,
  "-Oz",
  "--strip-debug",
  "--enable-bulk-memory"
);

system $wasm_opt_path, @args;

if ($? != -1) {
  my $new_size = -s $output_path;

  say "Optimised $game_wasm successfully";
  # say "Size: " . $original_size . " --> " . $new_size

  printf(
    "Size: %d (%d KB) --> %d (%d KB)",
    $original_size, ceil($original_size / 1024),
    $new_size, ceil($new_size / 1024))
} else {
  say "Failed to optimise."
}