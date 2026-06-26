use strict;
use warnings;
use v5.38.0;

use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use File::Copy::Recursive qw(dircopy);

# Copy build scripts

my $dest = abs_path(".");
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

mkdir "shared" unless -d "shared";
mkdir "units" unless -d "units";

for (glob "../experimental/units/*.{pas,PAS}") {
  my $filename = basename($_);

  copy($_, catfile($dest, "shared/$filename"))
    or warn "Couldn't copy $_: $!";
}

# Pull files from hello_demoscene

dircopy("../DEMOS/hello_demoscene", $dest);

# Handle project.lpi

say "Processing project.lpi...";

my $other_unit_dirs = "units;shared";

my $fh;
open ($fh, "<", "project.lpi")
  or die "Couldn't open project.lpi: $!";

my @lines = ();

while (my $line = <$fh>) {
  chomp $line;

  if ($line =~ /otherunitfiles/i) {
    $line =~ s/(value=\")(.*)(\")/$1$other_unit_dirs$3/i
  }

  push @lines, $line
}

close $fh;

open ($fh, ">", "project.lpi");
say $fh, $_ for @lines;
close $fh
