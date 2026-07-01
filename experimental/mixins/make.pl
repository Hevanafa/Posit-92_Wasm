use strict;
use warnings;
use v5.38.2;

use FindBin qw($Bin);
use File::Which qw(which);

my $script_dir = $Bin;
my $source_file = $ARGV[0];

unless ($source_file) {
  say "Usage: $0 <source_file.ts>";
  exit 1
}

unless (which "bun") {
  say "This script requires Bun JS runtime";
  say "https://bun.com/";
  exit 1
}

system "bun build $source_file --outdir $script_dir"
