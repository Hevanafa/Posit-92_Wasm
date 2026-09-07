use strict;
use warnings;
use v5.38.2;

my $fh;
my $font_def = "p92_sans_8.txt";

open $fh, "<", $font_def;

my @lines = <$fh>;

close $fh;

@lines = map {
  chomp;
  my $line = $_;
  $line =~ s/xoffset=(-?\d)/xoffset=0/;
  $line
} @lines;

open $fh, ">", $font_def;

say $fh $_ for @lines;

close $fh
