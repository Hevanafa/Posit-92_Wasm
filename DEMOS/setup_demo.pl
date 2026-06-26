use strict;
use warnings;
use v5.38.2;

use Cwd qw(getcwd);
use Term::ANSIColor qw(colored);

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
chdir "..";

my $engine_js_path = "../experimental/engine/posit-92.js";

say "Copying " . basename($engine_js_path) . "...";
copy $engine_js_path, catfile($dest, basename($engine_js_path));

# Copy build scripts

say "Copying build scripts..."

my $scripts_dir = abs_path("../scripts");

my @scripts = (
  "clean.pl", "make_demo.pl", "dist.pl",
  "server.ts"
);

for (@scripts) {
  copy(catfile($scripts_dir, $_), catfile($dest, $_))
    or warn "Couldn't copy $_: $!";
}

say colored("Done!", "bright_green")
