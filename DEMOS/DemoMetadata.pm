package DemoMetadata;

use strict;
use warnings;
use v5.38.2;

use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use File::Basename qw(basename dirname);

use Exporter "import";
our @EXPORT_OK = qw(read_mixins);

my $DEBUG = 0;
my $project_root = catdir($Bin, "..");

sub read_mixins {
  my @mixins = ();
  my $demo_name = shift;  # $ARGV[0] =~ /([a-z_]+)/;

  my $demo_dir = catdir($project_root, "DEMOS", $demo_name);
  say "demo_dir: ".$demo_dir;

  unless (-d $demo_dir) {
    say "Couldn't find ".$demo_dir."!";
    return @mixins
  }

  my $lpr_file = catfile($demo_dir, "game.lpr");
  say "lpr_file: ".$lpr_file;

  unless (-f $lpr_file) {
    say "Missing game.lpr for demo ".$demo_name."!";
    say "Likely using an older version of Posit-92 (WASM)";

    return @mixins
  }

  open my $fh, "<", $lpr_file;

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

  @mixins
}

1