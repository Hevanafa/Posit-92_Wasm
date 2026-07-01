use strict;
use warnings;
use v5.38.2;

my $mixin_name = $ARGV[0];

unless ($mixin_name) {
  say "Usage:";
  say "$0 <mixin_name>";
  say "";
  say "mixin_name must refer to a TypeScript source file";

  exit 1
}
