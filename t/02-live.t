# 02-live.t
#
# Test suite for WWW::Velib
# Try a real connection
#
# copyright (C) 2007 David Landgren

use strict;

use Test::More;
use WWW::Velib;

my $login = $ENV{PERL_TESTING_WWW_VELIB_LOGIN};
my $pin   = $ENV{PERL_TESTING_WWW_VELIB_PIN};

if (!defined $login and !defined $pin) {
    plan skip_all => 'PERL_TESTING_WWW_VELIB_* environment variables not set, see README';
    exit;
}

plan tests => 3;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

my $v = WWW::Velib->new( login => $login, pin => $pin );

is(ref($v), 'WWW::Velib', 'instantiated a live object');

cmp_ok(length($v->{html}{myaccount}), '>', 0, 'got some content');

is( $_, $Unchanged, $Unchanged );
