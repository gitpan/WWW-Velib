# generate Makefile for building WWW::Velib
#
# Copyright (C) 2007 David Landgren

use strict;
use ExtUtils::MakeMaker;

eval "use ExtUtils::MakeMaker::Coverage";
$@ or print "Adding testcover target\n";

WriteMakefile(
    NAME          => 'WWW::Velib',
    VERSION_FROM  => 'Velib.pm',
    ABSTRACT_FROM => 'Velib.pm',
    AUTHOR        => 'David Landgren',
    LICENSE       => 'perl',
    PREREQ_PM => {
        'WWW::Mechanize' => 0,
		'Crypt::SSLeay'  => '0.53',
    },
);
