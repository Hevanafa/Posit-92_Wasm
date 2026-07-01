

package DemoMetadata;

use strict;
use warnings;
use v5.38.2;

use Exporter "import";
our @EXPORT_OK = qw(read_mixins);

use Cwd qw(cwd);

my $DEBUG = 0;

# unless ($ARGV[0]) {
#   say "Usage:";
#   say "$0 <demo_dir>";
#   exit 1
# }

sub read_mixins {
  my @mixins = ();

  my $original_dir = cwd;
  my ($demo_dir) = @_;  # $ARGV[0] =~ /([a-z_]+)/;

  unless (-d $demo_dir) {
    say "Couldn't find ".$demo_dir."!";
    return @mixins
  }

  if ($DEBUG) {
    say "chdir to ".$demo_dir."..."
  }

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

      return @mixins
    }

    last if $line =~ /{/;
  }

  for $line (<$fh>) {
    if ($line =~ /mixins:/i) {
      chomp $line;

      say $line if $DEBUG;

      my ($mixins) = $line =~ /[:](.*)/;

      @mixins = map {
        $_ =~ /^\s*(.+)\s*$/;
        $1
      } $mixins =~ /[^,]+/g;

      if ($DEBUG) {
        say "Required mixins: ".(join " -- ", @mixins)
      }

      last
    }

    last if $line =~ /}/;
  }

  close $fh;

  if ($DEBUG) {
    say "Returning to ".$original_dir."..."
  }

  chdir $original_dir;

  @mixins
}

1