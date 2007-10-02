# 00-author.t
#
# Test suite for WWW::Velib - test the POD
#
# copyright (C) 2007 David Landgren

use strict;

use Test::More;

if (!$ENV{PERL_AUTHOR_TESTING}) {
    plan skip_all => 'PERL_AUTHOR_TESTING environment variable not set (or zero)';
    exit;
}

eval qq{use Test::Pod};
my $has_test_pod = $@ ? 0 : 1;

eval qq{use Test::Pod::Coverage};
my $has_test_pod_coverage = $@ ? 0 : 1;

my $test_modules = $has_test_pod + $has_test_pod_coverage;

if ($test_modules > 1) {
    plan tests => $test_modules;
}
else {
    plan skip_all => 'POD and Kwalitee testing modules not installed';
}

SKIP: {
    skip( 'Test::Pod not installed on this system', 1 )
        unless $has_test_pod;
    pod_file_ok( 'Velib.pm' );
}

SKIP: {
    skip( 'Test::Pod::Coverage not installed on this system', 1 )
        unless $has_test_pod_coverage;
    pod_coverage_ok( 'WWW::Velib', 'POD coverage is go!' );
}
