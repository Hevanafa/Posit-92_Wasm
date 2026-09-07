use strict;
use warnings;
use v5.38.2;

my $fh;

open $fh, "<", "p92_sans_8.txt";

my @lines = <$fh>;

close $fh;

say for @lines;
