#!perl
#
# 2015 (c) Andrei Kovbovich akovbovich@gmail.com
#
use strict;
use warnings;

use lib 'lib';

my $grammar
    = do
{   use Parser::Combinators;
    use RPN;

    # I'm gonna go build my own theme park, with blackjack
    # and monadic parser combinators. In fact, forget the park!
    
    my $concat = sub { $_[0] . $_[1] };
    my $accum  = sub { push @{$_[0]}, $_[1]; $_[0]; };
    my @expr_lexem = ('0'..'9', qq/+ - x : ( ) ./, ',', ' ');
    
    my $dashes     = p_ws >> p_str('-----');
    my $start_tok  = p_ws >> p_str('START');
    my $end_tok    = p_ws >> p_str('END');
    my $block_name = p_ws >> p_plusf(p_alpha, $concat, '');

    my $var_assign = p_ws >> p_str(':=');
    my $var_name   = p_ws >> p_plusf(p_alpha, $concat, '');
    my $var_term   = p_ws >> p_char(';');
    my $var_expr   = p_manyf(p_char(@expr_lexem), $concat, '');

    my $var_def = $var_name >= sub
    {   my ($var) = @_;
    	$var_assign >> $var_expr >= sub
    	{   my ($expr) = @_;
    	    $var_term >= sub
    	    {   p_return [$var, evl(rpn($expr))];
    	    }
    	}
    };

    my $vars = p_manyf($var_def, $accum, []);
    
    my $grammar = $dashes >> $start_tok >> $block_name >= sub
    {   my ($block) = @_;
    	$dashes >> $vars >= sub
    	{   my ($varlist) = @_;
    	    $dashes >> $end_tok >> $block_name >= sub
    	    {   my ($block_) = @_;
		return p_return_failed unless $block eq $block_;
    		$dashes >= sub
		{   p_return [$block, $varlist];
		};
    	    };
    	};
    };
    
    $grammar;
};

use Parser;
use Foo;

my $parser = Parser->new($grammar, \&Foo::GetDataChunk);
my @output;

while (my $block = $parser->parse)
{   my $section = $block->[0];
    my $varlist = $block->[1];
    push @output, map { "$section.${\$_->[0]} = ${\$_->[1]};" } @$varlist;
    undef @$varlist;
}

print "$_\n" for (sort @output);
