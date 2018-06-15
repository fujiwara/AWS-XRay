package AWS::XRay;

use 5.012000;
use strict;
use warnings;
use parent qw/Class::Data::Inheritable/;

use Crypt::URandom ();
use IO::Socket::INET;
use Time::HiRes ();
use AWS::XRay::Segment;

use Exporter 'import';
our @EXPORT_OK = qw/ new_trace_id trace /;

our $VERSION = "0.01";

our $TRACE_ID;
our $SEGMENT_ID;
our $ENABLED = 1;

my $Sock;

__PACKAGE__->mk_classdata( daemon_host => "127.0.0.1" );
__PACKAGE__->mk_classdata( daemon_port => "127.0.0.1" );

sub sock {
    $Sock //= IO::Socket::INET->new(
        PeerAddr => __PACKAGE__->daemon_host,
        PeerPort => __PACKAGE__->daemon_port,
        Proto    => "udp",
    );
}

sub new_trace_id {
    sprintf(
        "1-%x-%s",
        CORE::time(),
        unpack("H*", Crypt::URandom::urandom(12)),
    );
}

sub new_id {
    unpack("H*", Crypt::URandom::urandom(8))
}

sub trace ($&) {
    my ($name, $code) = @_;

    return $code->(AWS::XRay::Segment->new) if !$ENABLED;

    local $AWS::XRay::TRACE_ID = $AWS::XRay::TRACE_ID // new_trace_id();

    my $segment = AWS::XRay::Segment->new({ name => $name });
    local $AWS::XRay::SEGMENT_ID = $segment->{id};

    my @ret;
    eval {
        if (wantarray) {
            @ret = $code->($segment);
        }
        else {
            $ret[0] = $code->($segment);
        }
    };
    my $error = $@;
    if ($error) {
        $segment->{error} = Types::Serialiser::true;
        $segment->{cause} = {
            exceptions => [
                {
                    id      => new_id(),
                    message => "$error",
                    remote  => Types::Serialiser::true,
                },
            ],
        };
    }
    eval {
        $segment->send();
    };
    if ($@) {
        warn $@;
    }
    die $error if $error;
    return wantarray ? @ret : $ret[0];
}

1;
__END__

=encoding utf-8

=head1 NAME

AWS::XRay - AWS X-Ray tracing library

=head1 SYNOPSIS

    use AWS::XRay qw/ trace /;

    trace "myApp", sub {
        trace "remote", sub {
            # do something ...
            trace "nested", sub {
                # ...
            };
        };
        trace "myHTTP", sub {
            my $segment = shift;
            # ...
            $segment->{http} = { # modify segument document
                request => {
                    method => "GET",
                    url    => "http://localhost/",
                },
                response => {
                    status => 200,
                },
            };
        };
    };

=head1 DESCRIPTION

AWS::XRay is a tracing library with AWS X-Ray.

AWS::XRay sends segment data to L<AWS X-Ray Daemon|https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html>.

=head1 FUNCTIONS

=head2 new_trace_id

Generate a Trace ID. (e.g. "1-581cf771-a006649127e371903a2de979")

L<Document|https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-traceids>

=head2 trace($name, $code)

trace() executes $code->($segment) and send the segment document to X-Ray daemon.

$segment is a AWS::XRay::Segment object.

When $AWS::XRay::TRACE_ID is not set, generates TRACE_ID automatically.

When trace() called in parent trace(), $segment is a sub segment document.

See also L<AWS X-Ray Segment Documents|https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html>.

=head2 daemon_host

Set a address for X-Ray daemon. defult "127.0.0.1".

    AWS::XRay->daemon_host("example.com");

=head2 daemon_port

Set a UDP port number for X-Ray daemon. defult 2000.

    AWS::XRay->daemon_port(2002);

=head2 $AWS::XRay::Enabled

Default true. When set false, trace() executes sub but do not send segument documents to X-Ray daemon.

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut

