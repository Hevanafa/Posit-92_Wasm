use strict;
use warnings;
use v5.38.0;

use FindBin qw($Bin);
use File::Path qw(remove_tree);
use File::Spec::Functions qw(catfile);

# Folders to nuke

my $script_dir = $Bin;

for my $dir (qw(backup lib)) {
  next unless -d $dir;
  remove_tree catfile($script_dir, $dir), { verbose => 1 }
}

# Generated file extensions

my @extensions = qw(wasm compiled o ppu);
my $pattern = join("|", @extensions);

for my $ext (@extensions) {
  for (glob catfile($script_dir, "*.$ext")) {
    unlink or warn "Could not delete $_: $!\n";
    say "Deleted $_"
  }
}
