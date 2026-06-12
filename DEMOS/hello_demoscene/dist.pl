use strict;
use warnings;
use v5.38.0;

use File::Copy qw(copy);
use File::Path qw(remove_tree);

my $wasm = "game.wasm";
my $dist_dir = "dist";

unless (-f $wasm) {
  say "Missing $wasm!";
  exit 1
}

remove_tree $dist_dir if -d $dist_dir;

mkdir $dist_dir;

# Copy base files
my @files = (
  $wasm,
  "game.js",
  "posit-92.js",
  "index.html",
  "favicon.ico"
);

for (@files) {
  copy $_, $dist_dir
}

# TODO: Copy assets
