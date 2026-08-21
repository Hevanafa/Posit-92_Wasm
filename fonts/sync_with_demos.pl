use strict;
use warnings;
use v5.38.2;

use File::Spec::Functions qw(catfile catdir);
use File::Copy;

my @files = (
  "p92_sans_11.png",
  "p92_sans_11.txt",
  "LICENSE.TXT"
);

# TODO: Copy to DEMOS
# TODO: Copy to TESTS

my $tests_dir = "../TESTS";

opendir(my $dh, $tests_dir);

my @test_dirs = grep {
  ($_ !~ /\.\.?/) && (-d catfile($tests_dir, $_))
} readdir $dh;

for my $proj_path (@test_dirs) {
  for (@files) {
    copy $_, catdir($proj_path, "assets", "fonts");
  }
}
