use strict;
use warnings;
use v5.38.2;

use File::Path qw(remove_tree);
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile catdir);

remove_tree catdir($Bin, "backup");
remove_tree catdir($Bin, "lib");

unlink catfile($Bin, "project.lps");

unlink catfile($Bin, "posit-92.js");
unlink for glob catfile($Bin, "*.mixin.js");
unlink catfile($Bin, "game.wasm");
