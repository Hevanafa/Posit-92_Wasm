use strict;
use warnings;
use v5.38.2;

use Cwd qw(getcwd);

# print join " -- ", @ARGV;

my $demo_dir = $ARGV[0];

if (!$demo_dir) {
  print "Missing $demo_dir!";
  exit 1
}

my $dest = catfile(getcwd, $demo_dir);

# TODO: Check --all

# Copy engine JS

eval {
  system "perl ../scripts/ensure_engine_js.pl";
  1
};

chdir $dest;

my $engine_js_path = "../experimental/engine/posit-92.js";

say "Copying " . basename($engine_js_path) . "...";
copy $engine_js_path, catfile($dest, basename($engine_js_path));

# Copy build scripts

my $scripts_dir = abs_path("../scripts");

my @scripts = (
  "clean.pl", "make_demo.pl", "dist.pl",
  "server.ts"
);

for (@scripts) {
  my $filename = basename($_);

  copy(catfile($scripts_dir, $_), catfile($dest, $filename))
    or warn "Couldn't copy $_: $!";
}
