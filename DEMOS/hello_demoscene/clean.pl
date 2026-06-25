use strict;
use warnings;
use v5.38.0;

use File::Path qw(remove_tree);
use File::Find;

# Folders to nuke
for my $dir (qw(backup lib)) {
  next unless -d $dir;
  remove_tree $dir, { verbose => 1 }
}

# Generated file extensions
my @extensions = qw(wasm compiled o ppu);
my $pattern = join("|", @extensions);

for my $ext (@extensions) {
  for (glob "*.$ext") {
    unlink or warn "Could not delete $_: $!\n";
    say "Deleted $_"
  }
}
