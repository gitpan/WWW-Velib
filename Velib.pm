# Velib.pm - WWW::Velib
#
# Copyright (c) 2007 David Landgren
# All rights reserved

package WWW::Velib;
use strict;

use vars qw/$VERSION/;
$VERSION = '0.01';

use WWW::Mechanize;
use WWW::Velib::Trip;

use constant HOST      => 'https://abofr-velib.cyclocity.fr/';
use constant LOGIN_URL => HOST . 'service/login';
use constant ACCT_URL  => HOST . 'service/myaccount';
use constant MONTH_URL => HOST . 'service/myaccount/month';

sub new {
    my $class = shift;
    my $self  = {};

    pop @_ if @_ % 2; # discard last odd garbage element so we can hashify
    my %arg = @_;

    if (@_ == 2) {
        for (1..2) {
            my $value = shift;
            $value =~ /\A(\d{10})\z/ and $self->{login} = $1;
            $value =~ /\A(\d{4})\z/  and $self->{pin}   = $1;
        }
    }

    exists $arg{login} and $self->{login} = delete $arg{login};
    exists $arg{defer} and $self->{defer} = delete $arg{defer};
    exists $arg{cache_dir} and $self->{cache_dir} = delete $arg{cache_dir};

    # pin takes priority over password as a named param
    exists $arg{password} and $self->{pin} = delete $arg{password};
    exists $arg{pin}      and $self->{pin} = delete $arg{pin};

    for my $key (qw(login pin)) {
        exists $self->{$key} or $self->{defer} or do {
            require Carp;
            Carp::croak("No $key parameter specified in new()\n");
        };
    }
    $self->{mech} = WWW::Mechanize->new or do {
        require Carp;
        Carp::croak("Failed to build WWW::Mechanizer object\n");
    };
    $self->{mech}->env_proxy();
    $self->{connected} = 0;

    bless $self, $class;
    if ($self->{defer}) {
        $arg{myaccount} and $self->myaccount(delete $arg{myaccount});
        $arg{month}     and $self->get_month(delete $arg{month});
    }
    else {
        $self->_connect();
    }

    return $self;
}

sub _slurp {
    my $file = shift;
    local $/ = undef;
    open IN, $file or do {
        require Carp;
        Carp::croak("Cannot open $file for input: $!\n");
    };
    my $contents = <IN>;
    close IN;
    return $contents;
}

{
    my $timestamp;
    sub _out {
        my $html      = shift;
        my $cache_dir = shift;
        my $prefix    = shift;
        $timestamp  ||= sub {sprintf "%04d%02d%02d-%02d%02d%02d",
            $_[5]+1900, $_[4]+1, reverse(@_[0..3])}->(localtime);
        my $file = "$cache_dir/$prefix.$timestamp";
        open my $out, '>', $file;
        if ($out) {
            print $out $html;
            close $out;
        }
    }
}

sub _connect {
    my $self = shift;
    my $m = $self->{mech};

    $m->get('https://abofr-velib.cyclocity.fr/service/login');
    $self->{html}{initial} = $m->content;
    $self->{connected}     = 1;

    $m->form_number(4);
    $m->current_form->value('Login', $self->{login});
    $m->current_form->value('Password', $self->{pin});
    $m->click('LoginButton');

    $m->get('https://abofr-velib.cyclocity.fr/service/myaccount');
    $self->{html}{myaccount} = $m->content;
    if ($self->{cache_dir} and -d $self->{cache_dir}) {
        _out($self->{html}{myaccount}, $self->{cache_dir}, 'myaccount');
    }

    $self->_myaccount_parse;
}

sub get_month {
    my $self = shift;
    if (defined(my $file = shift)) {
        $self->{html}{month} = _slurp($file);
    }
    else {
        my $m = $self->{mech};
        $self->_connect unless $self->{connected};
        $m->get(MONTH_URL);
        $self->{html}{month} = $m->content;
        if ($self->{cache_dir} and -d $self->{cache_dir}) {
            _out($self->{html}{month}, $self->{cache_dir}, 'month');
        }
    }

    my $month_isolate_re = qr{<table  border="0" class="detail_consommation">
\s*<tr >
\s*<th scope="col"> Date</th>
\s*<th scope="col"> Trajet</th>
\s*<th scope="col"> DurÃ©e</th>
\s*<th scope="col"> Montant</th>
\s*</tr>
((?:\s*<tr class="[^"]*">
\s*<td>&nbsp;[^<]+</td>
\s*<td>[^<]+</td>
\s*<td>[^<]+</td>
\s*<td>\S+ &euro;</td>
\s*</tr>)+)};

    my ($month_detail) = ($self->{html}{month} =~ /$month_isolate_re/);
    return unless defined $month_detail;

    my $detail_re = qr{\s*<tr class="[^"]*">
\s*<td>&nbsp;(\d\d/\d\d/\d\d\d\d)</td>
\s*<td>(.*?) -> ([^<]+)</td>
\s*<td>(\d+)h (\d+)min</td>
\s*<td>(\d+,\d+) &euro;</td>
\s*</tr>};

    if (my @match = $month_detail =~ /$detail_re/g) {
        while (@match) {
            push @{$self->{trip}},
                WWW::Velib::Trip->make(splice(@match, 0, 6));
        }
    }
}

sub myaccount {
    my $self = shift;
    my $file = shift;
    $self->{html}{myaccount} = _slurp($file);
    $self->_myaccount_parse;
}

sub _myaccount_parse {
    my $self = shift;
    my $html = $self->{html}{myaccount};

    my $abo_re = qr{<h2 class="pad_bot2">Mon compte</h2>
<div class="border_vert">\s*<div class="content">
\s*<h3 class="titre_top titre_top_compte">Mon abonnement</h3>
\s*<div class="breaker"></div>
\s*<div class="info_compte">
\s*<p><span>Votre compte prend fin le :</span> ([^<]+)</p>
\s*<p><span>Il vous reste encore (\d+) jours d'abonnement</span></p>
\s*<p><span>\s+Vous n'avez pas de vÃ©lo en cours de location\.};

    if ($html =~ /$abo_re/) {
        $self->{end_date} = $1;
        $self->{remain}   = $2;
    }
    else {
        $self->{end_date} = '';
        $self->{remain}   = 0;
    }

    my $solde_re = qr{<h3 class="titre_top titre_top_compte">
\s*Mon paiement en ligne</h3>
\s*<div class="breaker"></div>
\s*<div class="info_compte">
\s*<p><span>Solde :</span>(\S+) &euro;</p>};

    $self->{balance} = ($html =~ /$solde_re/) ? $1 : 0;
    $self->{balance} =~ tr/,/./;

    my $conso_re = qr{<h3 class="titre_top titre_top_compte2">Ma consommation en (\S+) (\d+)</h3>
\s*<div class="breaker"></div>
\s*<div class="results">
\s*<table border="0" summary="tableau de consomation">
\s*<tr>
\s*<th scope="col" class="col1">Nbre de trajets</th>
\s*<th scope="col" class="col4">Temps cumulÃ©</th>
\s*<th scope="col" class="col4">Montant</th>
\s*</tr>
\s*<tr class="pyjama">
\s*<td>(\d+)</td>
\s*<td>(?:(\d+)h )?(\d+)min</td>
\s*<td>(\S+) &euro;</td>};

    if ($html =~ /$conso_re/) {
        $self->{conso_month} = $1;
        $self->{conso_year}  = $2;
        $self->{conso_trips} = $3;
        $self->{conso_time}  = ($4 || 0) * 60 + $5;
        $self->{conso_bal}   = $6;
        $self->{conso_bal}   =~ tr/,/./;
    }
    else {
        $self->{conso_month} = '';
        $self->{conso_year}  = 0;
        $self->{conso_trips} = 0;
        $self->{conso_time}  = 0;
        $self->{conso_bal}   = 0;
    }
}

sub end_date {
    my $self = shift;
    return $self->{end_date};
}

sub remain {
    my $self = shift;
    return $self->{remain};
}

sub balance {
    my $self = shift;
    return $self->{balance};
}

sub conso_month {
    my $self = shift;
    return $self->{conso_month};
}

sub conso_year {
    my $self = shift;
    return $self->{conso_year};
}

sub conso_trips {
    my $self = shift;
    return $self->{conso_trips};
}

sub conso_time {
    my $self = shift;
    return $self->{conso_time};
}

sub conso_bal {
    my $self = shift;
    return $self->{conso_bal};
}

sub trips {
    my $self = shift;
    return $self->{trip} ? @{$self->{trip}} : ();
}

'The Lusty Decadent Delights of Imperial Pompeii';
__END__

=head1 NAME

WWW::Velib - Download account information from the Velib website

=head1 VERSION

This document describes version 0.01 of WWW::Velib, released
2007-10-02.

=head1 SYNOPSIS

  use WWW::Velib;

  my $v = WWW::Velib->new(login => '0000123456', password => '1234');
  $v->get_month;
  for my $trip ($v->trips) {
    print $trip->date, ' from ', $trip->from,
        ' to ', $trip->to, "\n";
  }

=head1 DESCRIPTION

I<Documentation en français ci-dessous>.

C<WWW::Velib> connects to the Velib web site with your credentials
and extracts the information concerning your account. The available
information includes the date your subscription expires, how many
trips made this month, their details, and more.

Detailed information regarding the trips you have made using the
Velib system are only available for the current month or three
weeks, whichever is longer. Beyond this time frame, this information
is no longer available on the web site. C<WWW::Velib> allows you
to download and store this information locally. From this you can
process the information to discover which station you use the most,
your average trip duration, on which days you made the most trips
and so on.

B<Please note>: try to avoid connecting to the site too often. The
information is reasonably static: once a day should be quite
sufficient.

=head1 METHODS

=over 4

=item new

Creates a new C<WWW::Velib> object. The main issue to resolve is
how you wish to initialise the object with your credentials. The
following named parameters are recognised:

=over 4

=item login

=item pin

The standard approach is to pass two named parameters, C<login> and
C<pin>. (C<password> is recognised as an alias for C<pin>).

   my $v = WWW::Velib->new(login => '0000123456', pin => '1234');

Note that both logins (account numbers) and PINs are both numeric.
If either start with 0, Perl will consider that the numbers are to
be interpreted in octal. It is therefore safer to quote them as
strings.

If you are lazy, you may dispense with the named parameters, and
simply pass in two parameters, both of which must be all-digits,
one being 10 digits long, the other being 4 digits long.

  my $v = WWW::Velib->new( '0001234567', '9876' );

=item defer

In normal use, as soon as a WWW::Velib object is instantiated, it
will immediately connect to the Velib website. This may be prevented
by using C<defer>

   my $v = WWW::Velib->new(login => '123', pin => '456', defer => 1);

In this case, the C<myaccount> method may be used to initiate the
download at the appropriate time. TODO: Ugly: this will be changed
in a future release.

=item cache_dir

If you want to save the downloaded HTML pages to a local directory,
the cache_dir parameter may be used to specifiy the name of the
directory.

  my $v = WWW::Velib->new(
    login     => '0000123456',
    pin       => '1234',
    cache_dir => '/home/user/moi/velib',
  );

The main account page will be stored as C<myaccount.yyyymmdd-hhmmss>
and the monthly details page will be stored as C<month.yyyymmdd-hhmmss>.

=back

=item myaccount

Accepts a filename containing the contents of the authenticated
account page.

=item get_month

Retrieves the details of the trips made during the current month.

=item balance

Returns the current balance of your account (in Euros).

=item end_date

Returns the date your Velib subscription expires.

=item remain

Returns the number of days left until the end of the Velib subscription.

=item conso_month

Returns the month (en français) of the account information (current
month if used online, otherwise the month appearing in the stored
file given to C<myaccount>.

=item conso_year

Returns the year of the account information.

=item conso_trips

Returns the number of trips (journeys) made this month.

=item conso_time

Returns the total amount of time (in minutes) taken this month.

=item conso_bal

Returns the current balance of your account (should be the same as
C<balance>).

=item trips

Returns an array containing the details of all the trip made in the
current month. Each element of the array is a C<WWW::Velib::Trip>
object: consult that page for information on how to process them.
The array is ordered in the same order as the trip details are
listed on the web page.

=back

=head1 DOCUMENTATION EN FRANÇAIS

C<WWW::Velib> établit une connexion au site Web de Velib avec vos
indentifiants et extrait l'information au sujet de votre compte.
L'information disponible inclut la date de la fin de votre abonnement,
combien de trajets vous avez fait ce mois-ci, ainsi que leurs détails.

L'information détaillée concernant les trajets que vous avez
effectué avec Velib ne sont disponibles que pour le mois courant
ou les trois dernières semaines. Passé ce délai, ces
informations ne sont plus disponible sur le site Web.

C<WWW::Velib> vous permet de télécharger et stocker cette information
en local. Vous pouvez alors analyser l'information recueillie pour
découvrir quelles stations vous employez le plus souvent, la durée
moyenne des trajets, quel jour vous avez fait le plus de voyages et ainsi
de suite.

TODO: étoffer la doc (y a-t-il des volontaires ?)

=head1 NOTES

This is beta code! The API is subject to change: the ugly C<defer> hack
must die, and there should be a way to loop through several months of
downloaded files.

=head1 ACKNOWLEDGEMENTS

Thanks to Max "Corion" Maischein for the wonderful C<WWW::Mechanize::Shell>
module that made the heavy lifting a snap to write.

=head1 SEE ALSO

=over 4

C<WWW::Mechanizer> - The only game in town for navigating web sites in Perl.

L<http://www.velib.paris.fr> - The official Paris Vélib' website.

L<https://abofr-velib.cyclocity.fr/> - The actual accounts website.

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

