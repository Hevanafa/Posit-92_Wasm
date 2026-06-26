use strict;
use warnings;
use v5.38.2;

use Cwd qw(abs_path getcwd);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use Term::ANSIColor qw(colored);

# print join " -- ", @ARGV;

my $demo_dir = $ARGV[0];

if (!$demo_dir) {
  say "Missing \$demo_dir!";
  say "Usage:";
  say "$0 <demo_dir> [--all]";
  exit 1
}

# TODO: Check --all

if (grep { $_ eq "--all" } @ARGV) {
  say "--all option is used";
  exit
}

my $dest = catfile(getcwd, $demo_dir);

# Copy engine JS

eval {
  system "perl ../scripts/ensure_engine_js.pl";
  1
};

# Return to DEMOS
chdir $dest;
chdir "..";

my $engine_js_path = "../experimental/engine/posit-92.js";

say "Copying " . basename($engine_js_path) . "...";
copy($engine_js_path, catfile($dest, basename($engine_js_path)));

# Copy build scripts

say "Copying build scripts...";

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
