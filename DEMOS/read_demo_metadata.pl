use strict;
use warnings;
use v5.38.2;

use Cwd qw(cwd);

my $original_dir = cwd;
my ($demo_dir) = $ARGV[0] =~ /([a-z_]+)/;

say "chdir to ".$demo_dir."...";
chdir $demo_dir;

open my $fh, "<", "game.lpr";

# TODO: Read the header

close $fh;

say "Returning to ".$original_dir."...";
chdir $original_dir
