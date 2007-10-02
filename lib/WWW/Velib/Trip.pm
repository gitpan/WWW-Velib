# Trip.pm - WWW::Velib::Trip
#
# Copyright (c) 2007 David Landgren
# All rights reserved

package WWW::Velib::Trip;
use strict;

use vars qw/$VERSION/;
$VERSION = '0.01';

sub make {
    my $class = shift;
    my $self  = {
        date     => $_[0],
        from     => $_[1],
        to       => $_[2],
        duration => $_[3] * 60 + $_[4],
        cost     => do {$_[5] =~ tr/,/./; $_[5]} + 0,
    };
    return bless $self, $class;
}

'The Lusty Decadent Delights of Imperial Pompeii';
__END__

=head1 NAME

WWW::Velib::Trip - Details of a single trip made on the Velib system

=head1 VERSION

This document describes version 0.01 of WWW::Velib, released
2007-xx-xx.

=head1 SYNOPSIS

  use WWW::Velib;

  my $v = WWW::Velib->new(login => '0000123456', password => '1234');
  $v->get_month;
  for my $trip ($v->trips) {
    print "Journey from ", $trip->{from}, " to ", $trip->{to},
      " took", $trip->{duration}, "minutes.\n";
  }

=head1 DESCRIPTION

=head1 METHODS

=over 8

=item from

=item to

=item duration

=back

=head1 AUTHOR

David Landgren, copyright (C) 2007. All rights reserved.

http://www.landgren.net/perl/

If you (find a) use this module, I'd love to hear about it. If you
want to be informed of updates, send me a note. You know my first
name, you know my domain. Can you guess my e-mail address?

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

