package Agent::TCLI::Package::UnixBase;
#
# $Id: UnixBase.pm 42 2007-04-02 20:20:14Z hacker $
#
=head1 NAME

Agent::TCLI::Package::UnixBase - Base object for Agent::TCLI::Package objects accessing other
Unix commands.

=head1 VERSION

This document describes Agent::TCLI::Package::UnixBase version 0.0.1

=head1 SYNOPSIS


=head1 DESCRIPTION

Base object for Packages needing to run other Unix programs. It provides methods
to asnychronously call Unix programs using POW::Wheel::Run and sets up simple
event handlers to accept the output and/or errors returned.

Typically, one may want their package subclass to replace the RunStdOut method
with one that does more processing of the response.

=head1 INTERFACE


=cut

use warnings;
use strict;
use Carp;
use Object::InsideOut qw(Agent::TCLI::Package::Base);

use POE qw(Wheel::Run);
#use Scalar::Util;
#use Getopt::Lucid;
#use YAML;
#use FormValidator::Simple;


our $VERSION = '0.0.'.sprintf "%04d", (qw($Id: UnixBase.pm 42 2007-04-02 20:20:14Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard accessor/mutator
methods unless otherwise noted


#=head3 name
#
#The name of the command. This is the word that is used to call the command.
#B<set_name> will only accept SCALAR type values.
#
#=cut
#my @name		:Field
#				:All('name');
#
#=head3 commands
#
#An array of the command objects in this package.
#
#=cut
#my @commands	:Field
#				:Arg('commands')
#				:Get('commands')
#				:Type('HASH');
#
#=head3 parameters
#
#A hash of the parameters used in this package. Often parameters are shared accross individual commands, so they are defined here.
#B<parameters> should only contain hash values.
#
#=cut
#my @parameters	:Field
#				:Type('HASH')
#				:Arg('parameters')
#				:Get('parameters');
#
#my @session 	:Field
#				:Arg('session')
#				:Weak;
##				:Type('POE::Session');
#
#=head3 opt
#
#An internal object for holding optional parameters. Defaults to Getopt::Lucid to process parameters
#B<opt> will only accept Getopt::Lucid types.
#
#=cut
#my @opt			:Field
#				:All('opt');
##				:Type('Getopt::Lucid');
#
#=head3 opt_args
#
#An array of the args passed in with a command for processing by Getopt::Lucid
#B<opt_args> will only accept ARRAY type values.
#
#=cut
#my @opt_args	:Field
#				:All('opt_args')
#				:Type('ARRAY');
#
#=head3 controls
#
#A hash of hashes keyed on control for storing stuff.
#
#=cut
#my @controls		:Field;

#=head3 requests
#
#A hash collection of requests that are in progress
#
#=cut
#my @requests		:Field
#					:Type('HASH')
#					:Arg('name' => 'requests', 'default' => { } )
#					:Acc('requests');

# Standard class utils are inherited

=head2 METHODS

Most of these methods are for internal use within the TCLI system and may
be of interest only to developers trying to enhance TCLI.

=head3 start

This POE event handler is called when POE starts up a Package.
The B<_start> method is :Cumulative within OIO. Ideally, most command packages
could use this Base _start method without implementing
their own. However there seems to be a race condition between the POE
initialization and the OIO object initialization. Until this is debugged
one will probably have to have this _start method in every package.

=cut

sub RunWheelForRequest {
	my ($self, $request, $program, $program_args) = @_;

	# When a generic shell just won't do, but now the Command needs to
	# properly designate the Program and args.

	# Unlike controls, where the command needs to track the wheels,
	# if it's per request, we'll just stuff the wheel into the request.

	my $control = $request->sender;

	$self->Verbose("RunWheelForRequest: request(".$request->id.") ",2);

	my $wheel = POE::Wheel::Run->new (
	  		# TODO set up better security on the shell
		    # Set the program to execute, and optionally some parameters.
		    Program     => $program,
			ProgramArgs => $program_args,

		    # Define I/O events to emit.  Most are optional.
		    #StdinEvent  => 'RunStdin',    # Flushed all data to the child's STDIN.
		    StdoutEvent => 'RunStdout',    # Received data from the child's STDOUT.
		    StderrEvent => 'RunStderr',    # Received data from the child's STDERR.
		    ErrorEvent  => 'RunError',          # An I/O error occurred.
		    CloseEvent  => 'RunChildClosed',  # Child closed all output handles.

		    # Optionally adjust the child process priority, user ID, and/or
		    # group ID.  You may need to be root to do this.
			#Priority    => +5,
			#User        => scalar(getpwnam 'nobody'),
			#Group       => getgrnam('nobody'),
		);

	$self->Verbose("RunWheelForRequest: new wheel (".$wheel->ID.") ",2);

	$self->SetWheelKey($wheel,'request',$request);

	$request->set_wheel_weak($wheel);

	return ($wheel);
}

#TODO This is broken. Control is not in Request anymore.
sub RunWheelForControl {
	my ($self, $request, $per_request) = @_;

	# When there is more than one run wheel per control, states can
	# get messed up. But this means that we only get back an ID tied to
	# this control and not to the individual command executed.
	# So we allow for a new wheel to be created per request, if desired.

	my $control = $request->sender;
	$self->SetControl($control) unless ( $self->GetControl( $control->id ) );
	$self->Verbose("RunWheelForControl: control(".$control->id.") ",2);

	my ($wheel, $controlkey);

	# if its per request, add request id to key
	$controlkey = $per_request ? $control->id.$request->id : $control->id;

	if ( !defined( $self->GetControlKey( $controlkey, 'wheel') ) )
	{
	  	$wheel = POE::Wheel::Run->new (
	  		# TODO set up better security on the shell
		    # Set the program to execute, and optionally some parameters.
		    Program     => '/bin/sh',
			#ProgramArgs => [],

		    # Define I/O events to emit.  Most are optional.
		    #StdinEvent  => 'RunStdin',    # Flushed all data to the child's STDIN.
		    StdoutEvent => 'RunStdout',    # Received data from the child's STDOUT.
		    StderrEvent => 'RunStderr',    # Received data from the child's STDERR.
		    ErrorEvent  => 'RunError',          # An I/O error occurred.
		    CloseEvent  => 'RunChildClosed',  # Child closed all output handles.

		    # Optionally adjust the child process priority, user ID, and/or
		    # group ID.  You may need to be root to do this.
			#Priority    => +5,
			#User        => scalar(getpwnam 'nobody'),
			#Group       => getgrnam('nobody'),
		);
		$self->SetcontrolKey( $controlkey, 'wheel', $wheel );
		$self->Verbose("RunWheelForControl: new wheel (".$wheel->ID.") ",2);
	}
	else
	{
		$wheel = $self->GetControlKey( $controlkey, 'wheel');
		$self->Verbose("RunWheelForControl: got wheel (".$wheel->ID.") ",2);
	}

	# this could overwrite a previous $request
	# if that's a problem, then use per_request wheels
	# otherwise it should all be going back to the same place
	$self->SetWheelKey($wheel,'request',$request);

	return ($wheel);
}

sub RunStdout {
    my ($kernel,  $self, $input, $wheel_id) =
      @_[KERNEL, OBJECT,   ARG0,      ARG1];
	$self->Verbose("RunStdout: got input($input) wheel_id(".$wheel_id.") ",2);

    my $request = $self->GetWheelKey( $wheel_id, 'request' );

	$request->Respond( $kernel, $input, 200);
}

sub RunStderr {
    my ($kernel,  $self, $input, $wheel_id) =
      @_[KERNEL, OBJECT,   ARG0,      ARG1];
	$self->Verbose("RunStderr: got input($input) wheel_id(".$wheel_id.") ",2);

    my $request = $self->GetWheelKey( $wheel_id, 'request' );

	$input = "STDERR: ".$input." !!! ";

	$request->Respond( $kernel, $input, 400);
}

sub RunError {
    my ($kernel,  $self, $operation, $errnum, $errstr, $wheel_id) =
      @_[KERNEL, OBJECT,       ARG0,    ARG1,    ARG2,     ARG3];

    $errstr = "remote end closed" if $operation eq "read" and !$errnum;
	my $input = "Wheel $wheel_id generated $operation error $errnum: $errstr\n";

	$self->Verbose("RunError: input($input)",2);
    my $request = $self->GetWheelKey( $wheel_id, 'request' );

	$request->Respond( $kernel, $input, 400) if defined($request);
}

#sub close_state {
#    my ($self, $wheel_id) = @_[OBJECT, ARG0];
#    my $child = $self->GetWheel( $wheel_id);
#    print "Child ", $child->PID, " has finished.\n";
#	$self->SetWheel( $wheel_id );
#}


1;

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
