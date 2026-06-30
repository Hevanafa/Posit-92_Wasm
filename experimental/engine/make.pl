use strict;
use warnings;
use v5.38.2;

use File::Which qw(which);

unless (which "bun") {
  say "This script requires Bun JS runtime";
  say "https://bun.com/";
  exit 1
}

system "bun build posit-92.ts --outdir ."
