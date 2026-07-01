use strict;
use warnings;
use v5.38.2;

use FindBin qw($Bin);
use File::Basename qw(basename);

my $script_dir = $Bin;

say "Checking engine JS...";

my $engine_js_path = catfile($script_dir, "posit-92.js");

unless (-f $engine_js_path) {
  my $cmd = "bun run make";
  say "Couldn't find the engine JS " . basename($engine_js_path);
  say "Invoking $cmd...";
  
  chdir "../experimental/engine";
  system $cmd or die "Couldn't execute $cmd: $!"
}
