use strict;
use warnings;
use v5.38.0;

use Term::ANSIColor qw(colored);

use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Path qw(remove_tree);

# Requires:
# cpanm File::Copy::Recursive
use File::Copy::Recursive qw(dircopy);

my $seven_zip_path = "C:/Program Files/7-Zip/7z.exe";
my $wasm = "game.wasm";

unless (-f $wasm) {
  say colored("Missing $wasm!", "red");
  exit 1
}

my $dist_dir = "dist";

remove_tree $dist_dir if -d $dist_dir;

mkdir $dist_dir;

$dist_dir = abs_path("dist");

# Copy main files

my @files = (
  $wasm,
  "game.js",
  "posit-92.css",
  "posit-92.js",
  "index.html",
  "favicon.ico"
);

for (@files) {
  copy($_, $dist_dir) or die "Couldn't copy $_: $!"
}

# Copy assets
dircopy(abs_path("assets"), "$dist_dir/assets") or
  warn "Couldn't copy assets: $!";

say colored("Copied to dist successfully!", "bright_green");

if (grep { $_ eq "--zip" } @ARGV) {
  unless (-f $seven_zip_path) {
    say "You don't have 7-zip installed at";
    say $seven_zip_path;
    exit 1
  }

  chdir $dist_dir;

  my @args = ("a", "dist.zip", "*");
  system $seven_zip_path, @args;  # or die "Couldn't make the ZIP file: $!";
  say colored("Created dist.zip", "bright_green")
}
