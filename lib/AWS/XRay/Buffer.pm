package AWS::XRay::Buffer;

use 5.012000;
use strict;
use warnings;

sub new {
    my $class = shift;
    my ($sock, $auto_flush) = @_;
    bless {
        buf        => "",
        sock       => $sock,
        auto_flush => $auto_flush,
    }, $class;
}

sub flush {
    my $self = shift;
    $self->{sock}->print($self->{buf});
    $self->{buf} = "";
    1;
}

sub print {
    my $self = shift;
    if ($self->{auto_flush}) {
        $self->{sock}->print(@_);
    }
    else {
        $self->{buf} .= $_ for @_;
    }
}

1;
