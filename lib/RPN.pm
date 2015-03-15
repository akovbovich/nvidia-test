#
# 2015 (c) Andrei Kovbovich akovbovich@gmail.com
#
package RPN;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw/rpn evl/;

sub w
{   s/\n([@_^+-])(.*)/ $2 $1/g;
    $_;
}

sub f
{   s/\(([^()]+)\)/f($_=$1)/e and f();
    w~w;
}

sub rpn {
    local $_ = $_[0];
    s/[\s\,]//g;
    s/([\d\.]+)/$1\n/g;
    f;
}

sub evl
{   local $_ = $_[0];
    eval
    {   local ($a, $b);
	for (split /\s/)
	{   /\d/ ? push @_, $_ : (
		$a = pop @_,
		$b = pop @_,
		push @_, (
		    '+' eq $_ ? $a + $b :
		    '-' eq $_ ? $b - $a :
		    'x' eq $_ ? $a * $b :
		    ':' eq $_ ? $b / $a :
		    die "invalid op\n"
		))
	}
	pop @_;
    } || 'NaN';
}

1;
