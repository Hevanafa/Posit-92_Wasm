use strict;
use warnings;
use v5.38.2;

use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);
use File::Which qw(which);

unless (which "bun") {
  say "This script requires Bun JS runtime";
  say "https://bun.com/";
  exit 1
}

my $script_dir = $Bin;
my $engine_src = catfile($script_dir, "posit-92.ts");

system "bun build $engine_src --outdir $script_dir"
