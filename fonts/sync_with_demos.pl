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
# Copy to TESTS

my $tests_dir = "../TESTS";

opendir(my $dh, $tests_dir);

my @test_dirs = grep {
  ($_ !~ /\.\.?/) && (-d catfile($tests_dir, $_))
} readdir $dh;

for my $proj_path (@test_dirs) {
  for (@files) {
    my $dest = catdir($tests_dir, $proj_path, "assets", "fonts");

    my $dest_path = catfile($dest, $_);
    say "Copying to ".$dest_path;
    copy $_, $dest
  }
}
