use 5.12.0;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay qw/ capture capture_from /;
use Test::More;
use Benchmark qw/ timeit timestr /;

my $sampler = {
    none         => sub { 0 },
    "50_percent" => sub { rand() < 0.5 },
    "1_percent"  => sub { rand() < 0.01 },
    all          => sub { 1 },
};

for my $name (sort keys %$sampler) {
    AWS::XRay->sampler($sampler->{$name});
    my $t = timeit(
        1000,
        sub {
            capture "root", sub {
                capture "sub $_", sub {} for ( 1 .. 99 );
            };
        });
    diag sprintf("sampler %s: %d loops of 100 captured code took: %s", $name, $t->iters, timestr($t));
}

ok 1;
done_testing;