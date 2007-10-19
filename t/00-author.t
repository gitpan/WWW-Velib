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
my $has_test_pod = $@ ? 0 : 4;

eval qq{use Test::Pod::Coverage};
my $has_test_pod_coverage = $@ ? 0 : 4;

my $test_modules = $has_test_pod + $has_test_pod_coverage;

if ($test_modules > 1) {
    plan tests => $test_modules;
}
else {
    plan skip_all => 'POD and Kwalitee testing modules not installed';
}

SKIP: {
    skip( 'Test::Pod not installed on this system', 4 )
        unless $has_test_pod;
    pod_file_ok( 'Velib.pm' );
    pod_file_ok( 'lib/WWW/Velib/Map.pm' );
    pod_file_ok( 'lib/WWW/Velib/Station.pm' );
    pod_file_ok( 'lib/WWW/Velib/Trip.pm' );
}

SKIP: {
    skip( 'Test::Pod::Coverage not installed on this system', 4 )
        unless $has_test_pod_coverage;
    pod_coverage_ok( 'WWW::Velib', 'POD coverage is go!' );
    pod_coverage_ok( 'WWW::Velib::Map', 'Map POD coverage is go!' );
    pod_coverage_ok( 'WWW::Velib::Station', 'Station POD coverage is go!' );
    pod_coverage_ok( 'WWW::Velib::Trip', 'Trip POD coverage is go!' );
}
