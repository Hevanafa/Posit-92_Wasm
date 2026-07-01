use strict;
use warnings;
use v5.38.2;

use File::Basename qw(basename);

my $mixin_name = $ARGV[0];

unless ($mixin_name) {
  say "Usage:";
  say "$0 <mixin_name>";
  say "";
  say "mixin_name must refer to a TypeScript source file";

  exit 1
}

# Normalise mixin name
$mixin_name = basename($mixin_name);

if ($mixin_name =~ /\.ts$/) {
  ($mixin_name) = $mixin_name =~ /(.*)\.ts/
}

my $source_file = $mixin_name . ".ts";

unless (-f $source_file) {
  say "Couldn't find ".$source_file."!";
  exit 1
}

say "Generating ".$mixin_name.".js...";
system "perl make.pl $source_file"
