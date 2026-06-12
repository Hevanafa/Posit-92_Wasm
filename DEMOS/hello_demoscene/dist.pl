use strict;
use warnings;
use v5.38.0;

use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
# use File::Find qw(find);
use File::Spec::Functions qw(catfile);

# Requires:
# cpanm File::Copy::Recursive
use File::Copy::Recursive qw(dircopy);

my $wasm = "game.wasm";
my $dist_dir = abs_path("dist");

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

# Copy assets
# find(sub {
#   my $path = $File::Find::name;
#
#   my $relative = $path =~ s/^assets\///r;
#   my $target = catfile("$dist_dir/assets", $relative);
#   say $target;
#
#   if (-d) {
#     make_path $target
#   } else {
#     copy($_, $target) or warn "Couldn't copy $relative: $!"
#   }
# }, "assets")

dircopy("assets", "$dist_dir/assets") or warn "Couldn't copy assets: $!"
