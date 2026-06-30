use strict;
use warnings;
use v5.38.2;

use Cwd qw(cwd);

my $original_dir = cwd;
my ($demo_dir) = $ARGV[0] =~ /([a-z_]+)/;

say "chdir to ".$demo_dir."...";
chdir $demo_dir;

open my $fh, "<", "game.lpr";

my $line;
my $skipped = 0;

# while-loop only reads up to that line, while for-loop is greedy -- it consumes the whole file

while ($line = <$fh>) {
  $skipped++ if $line !~ /{/;

  if ($skipped >= 10) {
    close $fh;
    say "Couldn't find any opening comments within the first 10 lines!";
    exit
  }

  last if $line =~ /{/;
}

for $line (<$fh>) {
  if ($line =~ /mixins:/i) {
    chomp $line;
    say $line;

    my ($mixins) = $line =~ /[:](.*)/;
    
    my @mixins = map {
      $_ =~ /^\s*(.+)\s*$/;
      $1
    } $mixins =~ /[^,]+/g;

    say "Required mixins: ".(join " -- ", @mixins);

    last
  }

  last if $line =~ /}/;
}

close $fh;

say "Returning to ".$original_dir."...";
chdir $original_dir
