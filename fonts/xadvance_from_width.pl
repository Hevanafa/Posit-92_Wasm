# Script to assign xadvance the same as glyph width
# Part of Posit-92 game engine

use strict;
use warnings;
use v5.38.2;

my $font_def = "p92_sans_11.txt";

open my $fh, "<", $font_def;

my @lines = map { chomp; $_ } <$fh>;

close $fh;

@lines = map {
  my $line = $_;

  if ($line =~ /^char /) {
    $line =~ /width=(\d+)/;
    my $width = $1;

    $line =~ s/xadvance=\d+/xadvance=$width/;
    $line
  } else {
    $_
  }
} @lines;

open $fh, ">", $font_def;
say $fh $_ for @lines;
close $fh
