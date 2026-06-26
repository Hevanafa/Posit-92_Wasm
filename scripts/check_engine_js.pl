use strict;
use warnings;
use v5.38.2;

# Copy engine JS

say "Checking engine JS...";

my $engine_js_path = "../experimental/engine/posit-92.js";

unless (-f $engine_js_path) {
  say "Couldn't find the engine JS " . basename($engine_js_path);
  
  chdir "../experimental/engine";
  system "bun run make"
}
