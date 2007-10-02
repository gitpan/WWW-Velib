# 02-live.t
#
# Test suite for WWW::Velib
# Try a real connection
#
# copyright (C) 2007 David Landgren

use strict;

use Test::More;
use WWW::Velib;

plan tests => 10;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

my $v = WWW::Velib->new(defer => 1);

is(ref($v), 'WWW::Velib', 'instantiated a deferred object');

$v->myaccount('eg/myaccount.html');

is($v->end_date, '21/07/2008', 'end_date');
is($v->remain, 302, 'remain');
is($v->balance, '0.00', 'balance');

is($v->conso_month, 'Septembre', 'conso_month');
is($v->conso_year, 2007, 'conso_year');
is($v->conso_trips, 61, 'conso_trips');
is($v->conso_time,  627, 'conso_time');
is($v->conso_bal, '0.00', 'conso_bal');

$v->get_month('eg/month.html');

is($_, $Unchanged, $Unchanged );
