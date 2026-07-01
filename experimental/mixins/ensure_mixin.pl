use strict;
use warnings;
use v5.38.2;

my $mixin_name = $ARGV[0];

unless ($mixin_name) {
  say "Usage:";
  say "$0 <mixin_name>";
  say "";
  say "mixin_name must refer to a TypeScript source file";

  exit 1
}

my $source_file = $mixin_name;
$source_file .= ".ts" if $mixin_name !~ /\.ts$/;

unless (-f $source_file) {
  say "Couldn't find ".$source_file."!";
  exit 1
}

say "Generating ".$mixin_name.".js...";
system "perl make.pl $source_file"
