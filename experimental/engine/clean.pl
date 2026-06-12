# Cleanup script for engine code

use strict;
use warnings;
use v5.38.0;

my $count = 0;
my @files = (
  glob("*.js"),
  glob("*.d.ts")
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
