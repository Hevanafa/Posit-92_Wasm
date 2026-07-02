use strict;
use warnings;
use v5.38.0;

use FindBin qw($Bin);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile catdir);
use File::Basename qw(basename);
use File::Copy::Recursive qw(dircopy);
use Term::ANSIColor qw(colored);

my $script_dir = $Bin;

my $project_root = catdir($Bin, "..");

my $engine_dir = catdir($project_root, "experimental", "engine");
my $scripts_dir = catdir($project_root, "scripts");
my $units_dir = catdir($project_root, "experimental", "units");

my $demoscene_dir = catdir($project_root, "DEMOS", "hello_demoscene");

# Copy engine JS

eval {
  my @args = (
    catdir($engine_dir, "ensure_engine_js.pl")
  );

  system "perl", @args;
  1
};

# Copy build scripts

say "Copying build scripts...";

my @scripts = (
  "clean.pl",
  "make.pl",
  "dist.pl",
  "server.ts"
);

for (@scripts) {
  copy(
    catfile($scripts_dir, $_),
    catfile($script_dir, $_))
      or warn "Couldn't copy $_: $!";
}

# Copy engine units

say "Copying engine units...";

mkdir "shared" unless -d "shared";
mkdir "units" unless -d "units";

for (glob catdir($units_dir, "*.{pas,PAS}")) {
  my $filename = basename($_);

  copy(
    $_,
    catfile($script_dir, "shared/$filename"))
      or warn "Couldn't copy $_: $!";
}

# Pull files from hello_demoscene

say "Cloning hello_demoscene...";

dircopy($demoscene_dir, $script_dir);

# Handle project.lpi

my $project_info_file = catfile($script_dir, "project.lpi");
my $other_unit_dirs = "units;shared";

say "Processing $project_info_file...";

my $fh;
open ($fh, "<", $project_info_file)
  or die "Couldn't open $project_info_file: $!";

my @lines = ();

while (my $line = <$fh>) {
  chomp $line;

  if ($line =~ /otherunitfiles/i) {
    $line =~ s/(value=\")(.*)(\")/$1$other_unit_dirs$3/i
  }

  push @lines, $line
}

close $fh;

open $fh, ">", $project_info_file;
say $fh $_ for @lines;
close $fh;

# Final copy step

my $engine_js_path = catfile($engine_dir, "posit-92.js");

say "Copying " . basename($engine_js_path) . "...";
copy $engine_js_path, catfile($script_dir, basename($engine_js_path));

say colored("Setup complete!", "bright_green");
say "Run perl .\\make.pl to build the WebAssembly, and then";
say "bun .\\server.ts to start the local server";
