use strict;
use warnings;
use v5.38.0;

use Term::ANSIColor qw(colored);

use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

use File::Copy qw(copy);
use File::Path qw(remove_tree);

# Requires:
# cpanm File::Copy::Recursive
use File::Copy::Recursive qw(dircopy);

my $seven_zip_path = "C:/Program Files/7-Zip/7z.exe";

my $script_dir = $Bin;

my $game_wasm = "game.wasm";
my $game_wasm_path = catfile($script_dir, $game_wasm);
my $dist_dir = catfile($script_dir, "dist");

unless (-f $game_wasm_path) {
  say colored("Missing game.wasm!", "red");
  exit 1
}

remove_tree $dist_dir if -d $dist_dir;

mkdir $dist_dir;

# Copy main files

my @files = (
  $game_wasm,
  "game.js",
  "posit-92.css",
  "posit-92.js",
  "index.html",
  "favicon.ico"
);

for (@files) {
  my $src_file = catfile($script_dir, $_);

  copy($src_file, $dist_dir) or die "Couldn't copy $_: $!"
}

# Copy assets
dircopy(catfile($script_dir, "assets"), catfile("$dist_dir", "assets")) or
  warn "Couldn't copy assets: $!";

say colored("Copied to dist successfully!", "bright_green");

if (grep { $_ eq "--zip" } @ARGV) {
  unless (-f $seven_zip_path) {
    say "You don't have 7-zip installed at";
    say $seven_zip_path;
    exit 1
  }

  my @args = ("a", catfile($script_dir, "dist.zip"), catfile($dist_dir, "*"));
  system $seven_zip_path, @args;  # or die "Couldn't make the ZIP file: $!";
  say colored("Created dist.zip", "bright_green")
}
