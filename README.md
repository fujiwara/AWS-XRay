# NAME

AWS::XRay - AWS X-Ray tracing library

# SYNOPSIS

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

# DESCRIPTION

AWS::XRay is a tracing library with AWS X-Ray.

AWS::XRay sends segment data to [AWS X-Ray Daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html).

# FUNCTIONS

## new\_trace\_id

Generate a Trace ID. (e.g. "1-581cf771-a006649127e371903a2de979")

[Document](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-traceids)

## trace($name, $code)

trace() executes $code->($segment) and send the segment document to X-Ray daemon.

$segment is a AWS::XRay::Segment object.

When $AWS::XRay::TRACE\_ID is not set, generates TRACE\_ID automatically.

When trace() called in parent trace(), $segment is a sub segment document.

See also [AWS X-Ray Segment Documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html).

## daemon\_host

Set a address for X-Ray daemon. defult "127.0.0.1".

    AWS::XRay->daemon_host("example.com");

## daemon\_port

Set a UDP port number for X-Ray daemon. defult 2000.

    AWS::XRay->daemon_port(2002);

## $AWS::XRay::Enabled

Default true. When set false, trace() executes sub but do not send segument documents to X-Ray daemon.

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
