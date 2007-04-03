package Agent::TCLI::Response;
#
# $Id: User.pm 119 2007-01-18 02:55:33Z hacker $
#
=head1 NAME

Agent::TCLI::Response - A Response class for Agent::TCLI::Response.

=head1 SYNOPSIS

A simple object for storing TCLI responses.

=cut

#use warnings;
#use strict;
#use Carp;

use Object::InsideOut qw(Agent::TCLI::Request);

our $VERSION = '0.'.sprintf "%04d", (qw($Id: User.pm 119 2007-01-18 02:55:33Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard get_ or set_
methods unless otherwise noted

=head3 body

Main body of response.

=cut
my @body			:Field
					:All('body');

=head3 code

A code for the response, similar to HTTP/SIP.
B<code> will only accept NUMERIC type values.

=cut
my @code			:Field
					:Type('NUMERIC')
					:All('code');

#=head3 request
#
#The request that this is a response to.
#B<request> will only accept Agent::TCLI::Response type values.
#
#=cut
#my @request			:Field
#					:Type('Agent::TCLI::Request')
#					:All('request');

1;
#__END__

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Request. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head2 BUGS

The (ab)use of AUTOMETHODS is probably more a bug than a feature.

SHOULDS and MUSTS are currently not always enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.
