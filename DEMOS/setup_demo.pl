use strict;
use warnings;
use v5.38.2;

use FindBin qw($Bin);
use Cwd qw(abs_path getcwd);
use File::Copy qw(copy);
use File::Spec::Functions qw(catdir, catfile);
use File::Basename qw(basename);
use Term::ANSIColor qw(colored);

use lib $Bin;
use DemoMetadata qw(read_mixins);

# print join " -- ", @ARGV;

my $script_dir = $Bin;

my $project_root = catdir($Bin, "..");

my $engine_dir = catdir($project_root, "experimental", "engine");
my $engine_js_path = catfile($engine_dir, "posit-92.js");

my $scripts_dir = catdir($project_root, "scripts");

my $demo_or_option = $ARGV[0];

if (!$demo_or_option) {
  say "Usage:";
  say "$0 <demo_or_option> [--all]";

  exit 1
}

# Ensure engine JS
eval {
  system "perl", catfile($scripts_dir, "ensure_engine_js.pl");
  1
};

sub setup_demo {
  my $target_dir = shift;

  unless ($target_dir) {
    say "Missing $target_dir parameter!";
    return
  }

  my $target_dir_abs = abs_path($target_dir);

  # Copy engine JS

  say "Copying " . basename($engine_js_path) . "...";
  copy($engine_js_path, catfile($target_dir, basename($engine_js_path)));

  # Handle mixins

  my @mixins = read_mixins $target_dir;
  # print join " -- ", @mixins;

  if (@mixins) {
    say "Copying mixin files...";

    chdir "../experimental/mixins/";

    for my $mixin_name (@mixins) {
      system "perl ensure_mixin.pl ".$mixin_name;

      copy($mixin_name.".js", catfile($target_dir_abs, $mixin_name.".js"))
        or warn "Couldn't copy mixin: $mixin_name"
    }

    chdir $start_dir;
  }

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
}

# Handle --all option

if (grep { $_ eq "--all" } @ARGV) {
  say "--all option is used";

  for my $demo_dir (grep { -d } glob "*") {
    say "Demo dir: ".$demo_dir;

    # TODO: actually do the setup
    # setup_demo $demo_dir;
    
    say ""
  }

  say colored("Done!", "bright_green");

  exit
}

# Otherwise handle setup for only 1 demo

my $demo_dir = $demo_or_option;

unless (-d $demo_dir) {
  say "Couldn't find ".$demo_dir."!";
  exit 1
}

# Normalise $demo_dir
($demo_dir) = $demo_dir =~ /([a-z_]+)/;

# Return to DEMOS

chdir $start_dir;

setup_demo $demo_dir;

say colored("Done!", "bright_green")
