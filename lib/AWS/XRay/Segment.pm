package AWS::XRay::Segment;

use 5.012000;
use strict;
use warnings;

use JSON::XS ();
use Time::HiRes ();

my $header = qq|{"format":"json","version":1}\n|;
my $json   = JSON::XS->new;

sub new {
    my $class = shift;
    my $src   = shift;

    my $segment = {
        %$src,
        id         => AWS::XRay::new_id(),
        start_time => Time::HiRes::time(),
    };
    if (my $parent_id = $AWS::XRay::CURRENT_ID) {
        # This is a sub segment.
        $segment->{parent_id} = $parent_id;
        $segment->{type}      = "subsegment";
        $segment->{namespace} = "remote";
    }
    bless $segment, $class;
}

sub send {
    my $self = shift;
    $self->{trace_id} //= $AWS::XRay::TRACE_ID;
    $self->{end_time} //= Time::HiRes::time();
    AWS::XRay::sock()->print($header, $json->encode({%$self}));
}

1;
