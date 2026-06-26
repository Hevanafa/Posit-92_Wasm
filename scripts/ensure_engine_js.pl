use strict;
use warnings;
use v5.38.2;

use File::Basename qw(basename);

# Copy engine JS

say "Checking engine JS...";

my $engine_js_path = "../experimental/engine/posit-92.js";

unless (-f $engine_js_path) {
  my $cmd = "bun run make";
  say "Couldn't find the engine JS " . basename($engine_js_path);
  say "Invoking $cmd...";
  
  chdir "../experimental/engine";
  system $cmd or die "Couldn't execute $cmd: $!"
}
