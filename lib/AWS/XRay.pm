package AWS::XRay;

use 5.012000;
use strict;
use warnings;

use Crypt::URandom ();
use IO::Socket::INET;
use Time::HiRes ();

use AWS::XRay::Segment;

use Exporter 'import';
our @EXPORT_OK = qw/ new_trace_id trace trace_root new_segment /;

our $VERSION = "0.01";

our $DAEMON_HOST = "127.0.0.1";
our $DAEMON_PORT = 2000;

our $TRACE_ID;
our $CURRENT_ID;

my $Sock;

sub daemon_host {
    my $class = shift;
    if (@_) {
        $DAEMON_HOST = shift;
        undef $Sock;
    }
    $DAEMON_HOST;
}

sub daemon_port {
    my $class = shift;
    if (@_) {
        $DAEMON_PORT = shift;
        undef $Sock;
    }
    $DAEMON_PORT;
}

sub sock {
    $Sock //= IO::Socket::INET->new(
        PeerAddr => $DAEMON_HOST,
        PeerPort => $DAEMON_PORT,
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

sub new_segment {
    my $src = shift;
    AWS::XRay::Segment->new($src);
}

sub trace_root {
    local $TRACE_ID = new_trace_id();
    trace(@_);
}

sub trace {
    my ($obj, $code, @args) = @_;

    if (!$AWS::XRay::TRACE_ID) {
        # not tracing
        return $code->(@args);
    }
    my $segment = new_segment($obj);
    local $AWS::XRay::CURRENT_ID = $segment->{id};

    my @ret;
    eval {
        if (wantarray) {
            @ret = $code->(@args);
        }
        else {
            $ret[0] = $code->(@args);
        }
    };
    my $error = $@;
    $segment->{end_time} = Time::HiRes::time();
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

    use AWS::XRay qw/ trace trace_root /;
    
    sub remote_access {
        my (@args) = @_;
        trace({ name => "externalApp1" }, sub { ... });
        trace({ name => "externalApp2" }, sub { ... });
    }

    # start tracing
    trace_root({ name => "myApp" }, sub { remote_access() }, "args");

    sub custom_trace {
        # custom segments
        my $segment = new_segment({
           name        => "myHTTP",
           annotations => {
             // ...
           },
           metadata => {
             // ...
           },
        });
        # ... process
        $segment->{http} = {
            request => {
                method => "GET",
                url    => "http://localhost/",
            },
            response => {
                status => 200,
            },
        };
        $segment->send();
    }

    trace_root({ name => "myApp" }, sub { custom_trace() });

=head1 DESCRIPTION

AWS::XRay is a tracing library with AWS X-Ray.

AWS::XRay sends segment data to L<AWS X-Ray Daemon|https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html>.

=head1 FUNCTIONS

=head2 new_trace_id

Generate a Trace ID. (e.g. "1-581cf771-a006649127e371903a2de979")

L<Document|https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-traceids>

=head2 trace_root($segment, $code, @args)

Start tracing with a new Trace ID.

$segment is a L<segment document|https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html> hashref.

"name" field is required.

This function executes $code->(@args) and send a segment document to X-Ray daemon.

=head2 trace($segment, $code, @args)

trace executes $code->(@args) and send a sub segment document to X-Ray daemon.

This function must be called from trace_root().

=head2 new_segment($src)

new_segment returns a L<AWS::XRay::Segment> object.

    local $AWS::XRay::TRACE_ID = new_trace_id();
    my $segment = new_segment({ name => "myApp" });
    {
        local $AWS::XRay::CURRENT_ID = $segment->{id};
        my $sub_segment = new_segment({ name => "mySub" });
        # ...
        $sub_segment->send();
    }
    $segment->send();

When $AWS::XRay::TRACE_ID is set, new_segment() returns a segment object.

When $AWS::XRay::CURRENT_ID is set, new_segment() returns a sub segment object.

=head2 daemon_host

Set a address for X-Ray daemon. defult "127.0.0.1".

    AWS::XRay->daemon_host("example.com");

=head2 daemon_port

Set a UDP port number for X-Ray daemon. defult 2000.

    AWS::XRay->daemon_port(2002);

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut

