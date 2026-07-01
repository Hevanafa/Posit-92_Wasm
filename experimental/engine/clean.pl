# Cleanup script for engine code

use strict;
use warnings;
use v5.38.0;

use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my $count = 0;
my @files = (
  glob(catfile($Bin, "*.js.map")),
  glob(catfile($Bin, "*.d.ts")),
  glob(catfile($Bin, "*.js"))
);

for my $file (@files) {
  next unless -f $file;
  if (unlink $file) {
    $count++
  } else {
    warn "Couldn't delete $file: $!"
  }
}

print "Deleted ".(scalar @files)." file(s)"
