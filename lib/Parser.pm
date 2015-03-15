#
# 2015 (c) Andrei Kovbovich akovbovich@gmail.com
#
package Parser;

use strict;
use warnings;

sub new
{   my ($pkg, $grammar, $data_provider) = @_;
    bless
    {	feed => $data_provider,
	p    => $grammar,
	buf  => "",
	eof  => 0,
    }, $pkg;
}

sub parse
{   my ($self) = @_;
    return if $self->{eof};
    
    my $read = sub
    {   my ($pos, $n) = @_;
	my $s = substr $self->{buf}, $pos, $n;
	return $s if length $s == $n;
	my $chunk;
	while (defined($chunk = $self->{feed}->()) and
	       defined($$chunk) and $$chunk ne '')
	{   $self->{buf} .= $$chunk;
	    $s = substr $self->{buf}, $pos, $n;
	    return $s if length $s == $n;
	}
	$self->{eof} = 1;
	return $s;
    };

    my $result = $self->{p}->($read, 0);
    my $result_class = ref $result;

    if ($result_class eq 'Failed')
    {   my ($chunk, $pos) = @$result;
	return if $self->{buf} !~ /\S/;
	my $s = substr $self->{buf}, $pos, 50;
	die "Parse error: $s\n";
    }

    my ($x, $chunk, $pos) = @$result;
    substr $self->{buf}, 0, $pos, '';

    $x;
}

1;
