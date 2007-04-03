package Agent::TCLI::Package::Tail::Line;
#
# $Id: Line.pm 42 2007-04-02 20:20:14Z hacker $
#
=head1 NAME

Agent::TCLI::Package::Tail::Line - A class for for lines to be tested.

=head1 SYNOPSIS

An object for storing Agent::TCLI::Test::Line information. Used to facilitate Agent::TCLI::Test::Tail.

=cut

use warnings;
use strict;

use Object::InsideOut qw(Agent::TCLI::Base);

our $VERSION = '0.'.sprintf "%04d", (qw($Id: Line.pm 42 2007-04-02 20:20:14Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard get_ or set_
methods unless otherwise noted

= cut

=head3 input

The 'line' as it is input into the cache. This may actually be another object to be tested against.

=cut
my @input			:Field
					:All('input');

=head3 count

The relative position within the test run of all lines.
B<count> will only contain numeric values.

=cut
my @count			:Field
					:Type('numeric')
					:All('count');

=head3 birth_time

The birth_time that the line hit the tail system.
B<birth_time> will only contain Numeric values.

=cut
my @birth_time		:Field
					:Type('Numeric')
					:All('birth_time');

=head3 ttl

Line time to live. Set as a time() value upon creation so this is the actual time the line should expire.
B<ttl> will only contain Numeric values.

=cut
my @ttl				:Field
					:Type('Numeric')
					:All('ttl');

=head3 source

A URI indicating the source of the line. Necessary for monitoring multiple sources.

=cut
my @source			:Field
					:All('source');

=head3 type

Describes the line type. "line" for plain text lines, ref($input) for objects. Perhaps others in the future.
B<type> will only contain scalar values.

=cut
my @type			:Field
#					:Type('scalar')
					:All('type');

# Standard class utils are inherited

=head2 METHODS

=head2 new ( hash of attributes )

See Attributes for their description.

=cut



1;
#__END__

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

SHOULDS and MUSTS are currently not enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
