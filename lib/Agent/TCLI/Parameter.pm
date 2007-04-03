package Agent::TCLI::Parameter;
#
# $Id: Parameter.pm 171 2007-03-23 22:52:02Z hacker $
#
=head1 NAME

Agent::TCLI::Parameter - A Parameter class for TCLI.

=head1 SYNOPSIS

#within a Agent::TCLI::Package module that inherits from Agent::TCLI::Package::Base
use Agent::TCLI::Parameter

sub _init :Init{
	$self->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: test_verbose
  constraints:
    - UINT
  help: an integer for verbosity
  manual: >
    This debugging parameter can be used to adjust the verbose setting
    for the test transport.
  type: counter
...
}

=head1 DESCRIPTION

Parameters are the arguements supplied with a command. TCLI defines them as
objects to make it easier to provide several necessary interface features
in a consistent manner. One can use the new function to create Parameters
to load into a package, but the author prefers the YAML syntax as it is
easier to work with.

Arguement parsing may be done with Getopt::Lucid. One should define the type
if using the provided parsing.

Arguement validation may be performed using FormValidator::Simple constraints
as defined in the parameter. Otherwise it should be performed within the
Package subroutine handling the command.

Typically each Package will have a field defined with a standard
accessor/mutator that represents the default value to be used for the
parameter when the command the command is called. This field can be
manually defined in the Package, or it can be autocreated upon parameter
loading within the Package. If necessary, the class filed may be used to
set the Object::InsideOut type to be used for the field.

The reason for the use of Parameter and Command objects is to push a Package
to be as data driven as possible, with only the only code being the actual
command logic. It was decided that it would be best to evolve towards that
goal, rather than try to get it right from the outset. So what you see what
you get.

=cut

use warnings;
use strict;

use Object::InsideOut qw(Agent::TCLI::Base);

our $VERSION = '0.0.'.sprintf "%04d", (qw($Id: Parameter.pm 171 2007-03-23 22:52:02Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard acessor/mutator
methods unless otherwise noted

=head3 name

The name of the parameter. The name is what the user supplies as an argument
to the Command. The name will also be used as the hash key when loaded
into the Package, so it must be unique within the set of all other Parameter
names in a package.

The parameter name is also specified in the Command definition within a module,
so the Parameter must be defined and loaded first.

If one desires to use the same name but needs different Parameter definitions
within a Package, one should consider whether use of the same name for
different things will lead to confusion for the users. If still convinced,
then use aliases or separate packages.

B<name> should only contain scalar values.

=cut
my @name			:Field
#					:Type('scalar')
					:All('name');

=head3 aliases

The aliases will be used by Getopt::Lucid in addition to the name when
parsing the arguments to a command. This allows one to create
variations on the argument name.
This is useful for verbose and other times when names might clash. One can
name the argument I<command_verbose> and create an alias of I<verbose>.

If B<aliases> are defined, they will be appended to the name in the Getopt::Lucid
specification. B<aliases> should being with an alias with
each subsequent alias separated by the vertical bar character. E.g.:

  name: command_verbose
  aliases: "verbose|v"

  means name "command_verbose", alias "verbose" and alias "v"

B<aliases> should only contain scalar values. When represented in YAML, they
should be quoted to keep YAML from trying to interpret the bars.

=cut
my @aliases			:Field
#					:Type('scalar')
					:All('aliases');

=head3 type

The type will be used by Getopt::Lucid to parse the arguments into the
parameters. It will also be used in a future HTTP inerface to determine
what type of form field to present to the user. Refer to Getopt::Lucid
for the complete details on how it works. A summary of the Getopt::Lucid
supported types:

=over 4

=item Switch -- a true/fals value

=item Counter -- a numerical counter

=item Param -- a variable taking an argument

=item List -- like param with list values

=item Keypair -- a variable taking an argument pair

=back

The use of a Keypair probably indicates the overloading of a single command
syntax and is discouraged. Instead, break the command into subcommands
if at all possible, and the resulting structure will likely be easier for
users.

B<type> should only contain scalar values.

=cut
my @type			:Field
#					:Type('scalar')
					:All('type');

=head3 help

A short description of the parameter. This should be a one-liner that is
used when the user asks for help on a particular command.
B<help> should only contain scalar values.

=cut
my @help			:Field
#					:Type('scalar')
					:All('help');

=head3 manual

A longer description of the parameter. This is displayed to the user when
the ask for a manual of a command. Currently, constraints are not automatically
used to generate additional manual content, but that is a desired feature.

B<manual> should only contain scalar values.

=cut
my @manual			:Field
#					:Type('scalar')
					:All('manual');

=head3 constraints

An array of constraints for the parameter. This will be fed to
FormValidator::Simple.
B<constraints> should only contain array values.

=cut
my @constraints		:Field
					:Type('ARRAY')
					:All('constraints');

=head3 default

The default value that the parameter has upon creation in the package.

=cut
my @default			:Field
					:All('default');

=head3 class

The class is used as the Object::InsideOut type if this parameter's field is
autocreated in the package when loaded. If the field already exists in the
Package, it will not be redefined and this won't be used.
B<class> should only contain scalar values.

=cut
my @class			:Field
#					:Type('scalar')
					:All('class');

=head3 show_method

If this parameter is stored within the Package as an object,
an array of objects, or a hash of objects, show_method can
be used to specify the object method that will
be used when 'show' is requested on the parameter. This will hopefully
allow the base show to cover 95% of all needs and reduce the need for
Package authors from having to write their own package->show.
B<show_method> should only contain scalar values.

=cut
my @show_method		:Field
#					:Type('scalar')
					:All('show_method');

# Standard class utils are inherited

=head2 METHODS

=head2 new ( hash of attributes )

See the attributes above for a description of the available attributes.

The preferred method of creating a Parameter object for a Package module
is to use the LoadYaml command in the module. This will create the object,
and insert it correctly into the Package parameter store.

=cut

=head2 alias (    )

An accessor to return all the aliases for this parameter

=head3 Description

Alias simply returns the name and aliases joined togetehr with a bar for use in Getopt::Lucid or a regular expression.

=head3  Usage

$object->alias()

=cut

sub alias {
  my $self = shift;
  if ( $self->aliases )
  {
  	return ( $self->name."|".$self->aliases )
  }
  else
  {
  	return ($self->name )
  }
} # End alias

1;
#__END__

=head1 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head2 BUGS

When naming parametersit is easy to accidentally
duplicate names and cause problems. The author expects that when he
makes this a habit, he'll try to fix it by doing something better than a loading
a hash with no validation.

SHOULDS and MUSTS are currently not always enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.
