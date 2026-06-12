use strict;
use warnings;
use v5.38.0;

my $wasm = "game.wasm";
my $dist_dir = "dist";

unless (-f $wasm) {
  say "Missing $wasm!";
  exit 1
}

remove_tree $dist_dir if -d $dist_dir;

mkdir $dist_dir;

# TODO: Copy base files
# TODO: Copy assets
