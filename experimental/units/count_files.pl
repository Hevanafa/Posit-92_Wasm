# Script to count files that are pending rename
# This script can be deleted after the P92 prefixing is done

use strict;
use warnings;
use v5.38.2;

my @files = (glob("*.PAS"), glob("*.pas"));
@files = grep { $_ !~ /^P92/ } @files;

for (@files) {
 say $_
}

say "Found ".@files." files pending rename"
