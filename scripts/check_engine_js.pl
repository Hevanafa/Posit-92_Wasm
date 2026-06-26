use strict;
use warnings;
use v5.38.2;

unless (-f "../experimental/engine/posit-92.js") {
  say "Couldn't find the engine JS posit-92.js";
  
  chdir "../experimental/engine";
  system "bun run make"
}
