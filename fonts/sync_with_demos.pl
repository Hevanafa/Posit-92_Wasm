use strict;
use warnings;
use v5.38.2;

my @files = (
  "p92_sans_11.png",
  "p92_sans_11.txt",
  "LICENSE.TXT"
);

# TODO: Copy to DEMOS
# TODO: Copy to TESTS
#
my $tests_dir = "../TESTS";

opendir my $dh, $tests_dir;

say for grep {
  ($_ !~ /\.\.?/) && (-d $tests_dir.$_)
} readdir $dh;
