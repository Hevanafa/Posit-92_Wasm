use strict;
use warnings;
use v5.38.0;

use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);

my $dest = abs_path(".");

# Copy build scripts

my $scripts_dir = abs_path("../scripts");
my @scripts = ("clean.pl", "dist.pl", "server.ts");

for (@scripts) {
  copy(catfile($scripts_dir, $_), $dest) or warn "Couldn't copy $_: $!";
}
