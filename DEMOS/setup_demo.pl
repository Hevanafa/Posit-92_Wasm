use strict;
use warnings;
use v5.38.2;

use Cwd qw(abs_path getcwd);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use Term::ANSIColor qw(colored);

use lib ".";
use DemoMetadata qw(read_mixins);

# print join " -- ", @ARGV;

my $start_dir = getcwd;
my $demo_dir = $ARGV[0];

if (!$demo_dir) {
  say "Missing \$demo_dir!";
  say "Usage:";
  say "$0 <demo_dir> [--all]";
  exit 1
}

unless (-d $demo_dir) {
  say "Couldn't find ".$demo_dir."!";
  exit 1
}

# Ensure engine JS
eval {
  system "perl ../scripts/ensure_engine_js.pl";
  1
};

# Return to DEMOS
chdir $start_dir;


my $engine_js_path = "../experimental/engine/posit-92.js";
my $scripts_dir = "../scripts";

# --all option

if (grep { $_ eq "--all" } @ARGV) {
  say "--all option is used";

  for $demo_dir (grep { -d } glob "*") {
    say "Demo dir: ".$demo_dir;

    # Copy engine JS

    say "Copying " . basename($engine_js_path) . "...";
    copy($engine_js_path, catfile($demo_dir, basename($engine_js_path)));

    # Copy build scripts

    say "Copying build scripts...";

    my @scripts = (
      "clean.pl", "make_demo.pl", "dist.pl",
      "server.ts"
    );

    for (@scripts) {
      copy(catfile($scripts_dir, $_), catfile($demo_dir, $_))
        or warn "Couldn't copy $_: $!";
    }

    say ""
  }

  say colored("Done!", "bright_green");

  exit
}

# Take care of 1 demo

# Copy engine JS

say "Copying " . basename($engine_js_path) . "...";
copy($engine_js_path, catfile($demo_dir, basename($engine_js_path)));

# Obtain the list of mixins

my @mixins = read_mixins $demo_dir;
# print join " -- ", @mixins;

# TODO: Ensure mixin files
# TODO: Copy mixin files


# Copy build scripts

say "Copying build scripts...";

my @scripts = (
  "clean.pl", "make_demo.pl", "dist.pl",
  "server.ts"
);

for (@scripts) {
  copy(catfile($scripts_dir, $_), catfile($demo_dir, $_))
    or warn "Couldn't copy $_: $!";
}

say colored("Done!", "bright_green")
