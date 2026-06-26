use strict;
use warnings;
use v5.38.0;

use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use File::Copy::Recursive qw(dircopy);
use Term::ANSIColor qw(colored);

my $dest = abs_path(".");

eval {
  system "perl ../scripts/check_engine_js.pl";
  1
}

chdir $dest;

# Copy build scripts

say "Copying build scripts...";

my $scripts_dir = abs_path("../scripts");
my @scripts = (
  "clean.pl", "make.pl", "dist.pl",
  "server.ts"
);

for (@scripts) {
  my $filename = basename($_);

  copy(catfile($scripts_dir, $_), catfile($dest, $filename))
    or warn "Couldn't copy $_: $!";
}

# Copy engine units

say "Copying engine units...";

mkdir "shared" unless -d "shared";
mkdir "units" unless -d "units";

for (glob "../experimental/units/*.{pas,PAS}") {
  my $filename = basename($_);

  copy($_, catfile($dest, "shared/$filename"))
    or warn "Couldn't copy $_: $!";
}

# Pull files from hello_demoscene

say "Cloning hello_demoscene...";

dircopy("../DEMOS/hello_demoscene", $dest);

# Handle project.lpi

my $project_info_file = "project.lpi";
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

say "Copying " . basename($engine_js_path) . "...";
copy $engine_js_path, catfile($dest, basename($engine_js_path));

say colored("Setup complete!", "bright_green");
say "Run perl .\\make.pl to build the WebAssembly, and then";
say "bun .\\server.ts to start the local server";
