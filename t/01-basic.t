# 01-basic.t
#
# Test suite for WWW::Velib
# Make sure the basic stuff works
#
# copyright (C) 2007 David Landgren

use strict;

eval qq{ use Test::More tests => 2 };
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

use WWW::Velib;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

diag( "testing WWW::Velib v$WWW::Velib::VERSION" );

{
    my $v = WWW::Velib->new(login => '123456', pin => '9876', defer => 1);
    ok( defined($v), 'new() defines ...' );
    ok( ref($v) eq 'WWW::Velib', '... a WWW::Velib object' );
}

my $login = $ENV{PERL_TESTING_WWW_VELIB_LOGIN};
my $pin   = $ENV{PERL_TESTING_WWW_VELIB_PIN};
