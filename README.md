# NAME

AWS::XRay - AWS X-Ray tracing library

# SYNOPSIS

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

# DESCRIPTION

AWS::XRay is a tracing library with AWS X-Ray.

AWS::XRay sends segment data to [AWS X-Ray Daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html).

# FUNCTIONS

## new\_trace\_id

Generate a Trace ID. (e.g. "1-581cf771-a006649127e371903a2de979")

[Document](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-traceids)

## trace\_root($segment, $code, @args)

Start tracing with a new Trace ID.

$segment is a [segment document](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html) hashref.

"name" field is required.

This function executes $code->(@args) and send a segment document to X-Ray daemon.

## trace($segment, $code, @args)

trace executes $code->(@args) and send a sub segment document to X-Ray daemon.

This function must be called from trace\_root().

## new\_segment($src)

new\_segment returns a [AWS::XRay::Segment](https://metacpan.org/pod/AWS::XRay::Segment) object.

    local $AWS::XRay::TRACE_ID = new_trace_id();
    my $segment = new_segment({ name => "myApp" });
    {
        local $AWS::XRay::CURRENT_ID = $segment->{id};
        my $sub_segment = new_segment({ name => "mySub" });
        # ...
        $sub_segment->send();
    }
    $segment->send();

When $AWS::XRay::TRACE\_ID is set, new\_segment() returns a segment object.

When $AWS::XRay::CURRENT\_ID is set, new\_segment() returns a sub segment object.

## daemon\_host

Set a address for X-Ray daemon. defult "127.0.0.1".

    AWS::XRay->daemon_host("example.com");

## daemon\_port

Set a UDP port number for X-Ray daemon. defult 2000.

    AWS::XRay->daemon_port(2002);

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
