package AWS::XRay::Plugin::EC2;
use strict;
use warnings;

use HTTP::Tiny;


# for test
our $_base_url = "http://169.254.169.254/latest";

sub ID_ADDR() {
    return "$_base_url/meta-data/instance-id";
}

sub AZ_ADDR() {
    return "$_base_url/meta-data/placement/availability-zone";
}

our $METADATA;

sub apply_plugin {
    my ($class, $segment) = @_;

    $METADATA ||= do {
        my $ua = HTTP::Tiny->new(timeout => 1);

        my $instance_id = do {
            my $res = $ua->get(ID_ADDR);
            $res->{success} ? $res->{content} : '';
        };
        my $az = do {
            my $res = $ua->get(AZ_ADDR);
            $res->{success} ? $res->{content} : '';
        };

        +{
            instance_id       => $instance_id,
            availability_zone => $az,
        };
    };

    $segment->{origin}     = 'AWS::EC2::Instance';
    $segment->{aws}->{ec2} = $METADATA;
}

1;
