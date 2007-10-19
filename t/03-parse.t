# 03-parse.t
#
# Test suite for WWW::Velib
# Parse some local copies of real Velib pages
#
# copyright (C) 2007 David Landgren

use strict;

use Test::More;
use WWW::Velib;

plan tests => 25;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

my $v = WWW::Velib->new(defer => 1);

is(ref($v), 'WWW::Velib', 'instantiated a deferred object');

$v->myaccount('eg/myaccount.html');

is($v->end_date, '21/07/2008', 'end_date');
is($v->remain, 302, 'remain');
is($v->balance, '0.00', 'balance');
is($v->in_use, 0, 'in_use');

is($v->conso_month, 'Septembre', 'conso_month');
is($v->conso_year, 2007, 'conso_year');
is($v->conso_trips, 61, 'conso_trips');
is($v->conso_time,  627, 'conso_time');
is($v->conso_bal, '0.00', 'conso_bal');

$v->get_month('eg/month.html');

my @trip = $v->trips;
is (scalar(@trip), 62, 'took 62 trips');

my $trip = $trip[0];
is( ref($trip), 'WWW::Velib::Trip', 'consider a WWW::Velib::Trip object' );

is($trip->date, '23/09/2007', 'trip date');
is($trip->from, 'TURBIGO SAINTE ELISABETH', 'trip from');
is($trip->to, 'TURENNE BRETAGNE', 'trip to');
is($trip->duration, 5, 'trip duration');
is($trip->cost, 0, 'trip cost');

$trip = $trip[-1];
is($trip->date, '01/09/2007', 'trip date');
is($trip->from, 'TURBIGO SAINTE ELISABETH', 'trip from');
is($trip->to, 'TURBIGO', 'trip to');
is($trip->duration, 9, 'trip duration');
is($trip->cost, 0, 'trip cost');

$v->myaccount('eg/in_use.html');
is($v->balance, 12.34, 'balance 2');
is($v->in_use, 1, 'in_use 2');

is($_, $Unchanged, $Unchanged );
