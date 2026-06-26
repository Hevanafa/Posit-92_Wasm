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
my @scripts = ("clean.pl", "dist.pl", "server.ts");

for (@scripts) {
  copy(catfile($scripts_dir, $_), $dest) or warn "Couldn't copy $_: $!";
}

# Copy engine units

mkdir "units" unless -d "units";

mkdir "shared" unless -d "shared";

for (glob "../experimental/units/*.{pas,PAS}") {
  my $filename = basename($_);
  copy($_, catfile($dest, "shared/$filename")) or warn $!
}

# Pull files from hello_demoscene

# for (glob "../DEMOS/hello_demoscene/*.*") {
#   my $filename = basename($_);
#   copy($_, "./$filename") or warn $!
# }

dircopy("../DEMOS/hello_demoscene", $dest)
