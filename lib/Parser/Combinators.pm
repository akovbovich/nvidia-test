#
# 2015 (c) Andrei Kovbovich akovbovich@gmail.com
#
package Parser::Combinators;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw/
p_return p_return_failed p_bind p_many p_manyf p_ws p_alpha p_str p_s
p_char p_plus p_plusf p_seq p_opt p_any p_until p_untilf Parsed Failed
p_all_until p_digit p_char_any
/;

use overload '|'  => 'p_any';
use overload '>>' => 'p_seq';
use overload '>=' => 'p_bind';

sub Parsed { bless [@_], 'Parsed'; }
sub Failed { bless [@_], 'Failed'; }

sub p_char
{   my (@chars) = @_;
    my $pat = join '', @chars;
    bless sub
    {   my ($chunk, $pos) = @_;
	if ((my $c = $chunk->($pos, 1)) ne '')
	{   return (index($pat, $c) != -1)
		? Parsed $c, $chunk, $pos + 1
		: Failed $chunk, $pos;
	}
	return Failed $chunk, $pos;
    }
}

sub p_char_any
{   bless sub
    {   my ($chunk, $pos) = @_;
	my $c = $chunk->($pos, 1);
	if ($c ne '') { return Parsed $c, $chunk, $pos + 1; }
	else          { return Failed $c, $chunk, $pos; }
    }
}

sub p_str
{   my ($str) = @_;
    my $n = length $str;
    bless sub
    {   my ($chunk, $pos) = @_;
	my $s = $chunk->($pos, $n);
	return $str eq $s
	    ? Parsed $s, $chunk, $pos + $n
	    : Failed $chunk, $pos;
    }
}

sub p_return
{   my ($x) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;
	Parsed $x, $chunk, $pos;
    }
}

sub p_return_failed
{   bless sub
    {   my ($chunk, $pos) = @_;
	Failed $chunk, $pos;
    }
}

sub p_bind
{   my ($p_a, $fn) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;

	my $result = $p_a->($chunk, $pos);
	my $result_class = ref $result;

	if ($result_class eq 'Parsed')
	{   my ($x, $chunk, $pos) = @$result;
	    @_ = ($chunk, $pos);
	    goto ($fn->($x));
	}

	if ($result_class eq 'Failed')
	{   return Failed @$result;
	}
    }
}

sub p_seq # ab
{   my ($p_a, $p_b) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;
	
	my $result = $p_a->($chunk, $pos);
	my $result_class = ref $result;

	if ($result_class eq 'Parsed')
	{   my (undef, $chunk, $pos) = @$result;
	    @_ = ($chunk, $pos);
	    goto $p_b;
	}

	if ($result_class eq 'Failed')
	{   return Failed @$result;
	}
    }
}

sub p_opt # a?
{   my ($p_a, $defval) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;
	
	my $result = $p_a->($chunk, $pos);
	my $result_class = ref $result;

	if ($result_class eq 'Parsed')
	{   return $result;
	}
	if ($result_class eq 'Failed')
	{   return Parsed $defval, $chunk, $pos;
	}
    }
}

sub p_any # a|b
{   my ($p_a, $p_b) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;
	
	my $result = $p_a->($chunk, $pos);
	my $result_class = ref $result;

	if ($result_class eq 'Parsed')
	{   return $result;
	}
	if ($result_class eq 'Failed')
	{   @_ = ($chunk, $pos);
	    goto $p_b;
	}
    }
}

sub p_many # a*
{   my ($p_a) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;
	
	my $result = $p_a->($chunk, $pos);
	my $result_class = ref $result;

	if ($result_class eq 'Parsed')
	{   my (undef, $chunk, $pos) = @$result;
	    @_ = ($chunk, $pos);
	    goto (p_many($p_a));
	}
	if ($result_class eq 'Failed')
	{   return Parsed [], $chunk, $pos;
	}
    }
}

sub p_manyf # a* with mem
{   my ($p_a, $fn, $v0) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;
	
	my $result = $p_a->($chunk, $pos);
	my $result_class = ref $result;

	if ($result_class eq 'Parsed')
	{   my ($v, $chunk, $pos) = @$result;
	    @_ = ($chunk, $pos);
	    goto (p_manyf($p_a, $fn, $fn->($v0, $v)));
	}
	if ($result_class eq 'Failed')
	{   return Parsed $v0, $chunk, $pos;
	}
    }
}

sub p_plus # a+
{   my ($p_a) = @_;
    $p_a >> p_many($p_a);
}

sub p_plusf # a+ with mem
{   my ($p_a, $fn, $v0) = @_;
    $p_a >= sub
    {   my ($x) = @_;;
	p_manyf($p_a, $fn, $fn->($v0, $x));
    }
}

sub p_all_until
{   my ($p_a) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;

	my $result = $p_a->($chunk, $pos);
	my $result_class = ref $result;

	if ($result_class eq 'Parsed')
	{   return Parsed [], $chunk, $pos;
	}
	if ($result_class eq 'Failed')
	{   @_ = ($chunk, $pos);
	    goto (p_char_any >> p_all_until($p_a));
	}
    }
}

sub p_until
{   my ($p_a, $p_b) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;

	my $result = $p_a->($chunk, $pos);
	my $result_class = ref $result;
	
	if ($result_class eq 'Parsed')
	{   return Parsed [], $chunk, $pos;
	}
	if ($result_class eq 'Failed')
	{   @_ = ($chunk, $pos);
	    goto ($p_b >> p_until($p_a, $p_b));
	} 
   }
}

sub p_untilf
{   my ($p_a, $p_b, $fn, $v0) = @_;
    bless sub
    {   my ($chunk, $pos) = @_;

	my $result = $p_a->($chunk, $pos);
	my $result_class = ref $result;

	if ($result_class eq 'Parsed')
	{   return Parsed $v0, $chunk, $pos;
	}
	if ($result_class eq 'Failed')
	{   my $p_c = $p_b >= sub
	    {   my ($v) = @_;
		p_untilf($p_a, $p_b, $fn, $fn->($v0, $v));
	    };
	    @_ = ($chunk, $pos);
	    goto $p_c;
	}
    }
}

sub p_s     { p_char "\ ", "\t", "\n"; }
sub p_ws    { p_many(p_s); }
sub p_alpha { p_char 'a'..'z', 'A'..'Z'; }
sub p_digit { p_char '0'..'9'; }

1;
