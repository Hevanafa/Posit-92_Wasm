use strict;
use warnings;
use v5.38.2;

my $fh;

open $fh, "<", "p92_sans_11.txt";

my @lines = map { chomp; $_ } <$fh>;

close $fh;

@lines = map {
  my $line = $_;

  if ($line =~ /^char /) {
    $line =~ /width=(\d+)/;
    my $width = $1;

    $line =~ s/xadvance=\d+/xadvance=$width/r;
    return $line
  }

  $_
} @lines;

open $fh, ">", "p92_sans_11.txt";

say $fh $_ for @lines;

close $fh
