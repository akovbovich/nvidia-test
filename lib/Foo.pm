#
# 2015 (c) Andrei Kovbovich akovbovich@gmail.com
#
package Foo;

use strict;
use warnings;

use Carp 'confess';

my $filename = $ARGV[0] || confess "\nusage:\n\t$0 filename\n\n";
my $bufsz = 1000*1024;

open my $fd, '<', $filename or die "open:$!\n";

sub GetDataChunk {
    if (my $n = sysread $fd, my $str, $bufsz, 0) {
	return \$str;
    }
    return; # EOD
}

1;
