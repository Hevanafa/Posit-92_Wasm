use strict;
use warnings;
use v5.38.2;

use File::Path qw(remove_tree);

remove_tree "backup";
remove_tree "bin";

unlink "project.lps";

unlink "posit-92.js";
unlink for glob "*.mixin.js";
unlink "game.wasm";
