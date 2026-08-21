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

# List DEMOS dirs

my $demos_dir = "../DEMOS";

my $dh;

opendir($dh, $demos_dir);

my @demo_dirs = grep {
  ($_ !~ /\.\.?/) && (-d catdir($demos_dir, $_))
} readdir $dh;

closedir $dh;

# List TESTS dirs

my $tests_dir = "../TESTS";

opendir($dh, $tests_dir);

my @test_dirs = grep {
  ($_ !~ /\.\.?/) && (-d catdir($tests_dir, $_))
} readdir $dh;

closedir($dh);

# Copy to DEMOS

for my $demo_path (@demo_dirs) {
  for (@files) {
    my $dest = catdir($demos_dir, $demo_path, "assets", "fonts");
    my $dest_path = catfile($dest, $_);

    say "Copying to ".$dest_path;
    copy $_, $dest
  }
}

# Copy to TESTS

for my $proj_path (@test_dirs) {
  for (@files) {
    my $dest = catdir($tests_dir, $proj_path, "assets", "fonts");
    my $dest_path = catfile($dest, $_);

    say "Copying to ".$dest_path;
    copy $_, $dest
  }
}
