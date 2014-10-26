# $Id: Base.pm 42 2007-04-02 20:20:14Z hacker $
package Agent::TCLI::Transport::Base;

=pod

=head1 NAME

Agent::TCLI::Transport::Test - transport for testing commands

=head1 SYNOPSIS

todo

=head1 DESCRIPTION

=over

=back

=head1 GETTING STARTED

=head2 DEFINING COMMANDS

=over 4

=item * args

=back

=head2 LAUNCHING THE CONTROL

=over 4

=item * commands

=item * hostname

=item * appname

=back

=head2 SHUTTING DOWN

=cut

# General setup {{{
use warnings;
use strict;
use Carp;

use POE;
use Agent::TCLI::Control;
use Agent::TCLI::Request;
require Agent::TCLI::Base;

use Object::InsideOut qw( Agent::TCLI::Base );

use Data::Dump qw(pp);
use YAML qw(freeze thaw);

#use Params::Validate qw(validate_with);

#use Sys::Hostname;
#use File::Basename;

our $VERSION = '0.'.sprintf "%04d", (qw($Id: Base.pm 42 2007-04-02 20:20:14Z hacker $))[2];

=head3 controls

A hash of the active controls
B<controls> will only accept hash objects.

=cut
my @controls 	:Field
				:All('controls')
				:Type('hash');

=head3 alias

An alias that the session will be run under. Alias can't be
changed after starting.

=cut
my @alias		:Field
				:Get('alias');

=head3 peers

An array of peers
B<set_peers> will only accept ARRAYREF type values.

=cut
my @peers		:Field
				:All('peers')
				:Type('ARRAY');

# Holds our session data. Made weak per Merlyn
# http://poe.perl.org/?POE_Cookbook/Object_Methods.
# We also don't take session on init.
my @session		:Field
				:Arg('session')
				:Get('session')
				:Weak;

=head3 control_options

A hash of options to pass to a new control object. These are passed
straight through as is. See Agent::TCLI::Control for information
about the options.
B<control_options> will only accept HASHREF type values.

=cut
my @control_options	:Field
					:All('control_options')
					:Type('HASHREF');

# Standard class utils are inherited

my %init_args :InitArgs = (
    'alias' => {
        'Default'		=> 'base',
    	'Field'			=> \@alias,
    },
);

#u_ subs can't be private if used in %init_args
#named u_ to sort nicer in Eclipse
sub u_is_text {
	return (
		 validate_pos( @_, { type => Params::Validate::SCALAR | Params::Validate::SCALARREF } )
		 )
}
sub u_is_num {
	return (
		 Scalar::Utils->looks_like_number($_[0])
		 )
}
sub u_is_int {
         my $arg = $_[0];
         return (Scalar::Util::looks_like_number($arg) &&
                 (int($arg) == $arg));
     }

sub spawn :Init {
	my ($self, $args) = @_;

#   Example simple session creation.
#	$self->set(\@session, POE::Session->create(
#        object_states => [
#        	$self => [ qw(
#	            _start
#            	_stop
#        	    _shutdown
#
#				SendRequest
#				SendResponse
#        	    SendChangeContext
#
#        	)],
#        ],
#   ));
}

=head2 _start

Get things rolling.

=cut

sub _start :Cumulative {
  my ($kernel,  $self, $session) =
    @_[KERNEL, OBJECT,  SESSION];

	# are we up before OIO has finished initializing object?
	if (!defined( $self->alias ))
	{
    $self->Verbose("_start: OIO not started delaying ",0);
		$kernel->call('_start');
		return;
	}

	# There is only one command object per TCLI
    $kernel->alias_set($self->alias);

    $self->Verbose("_start: Starting alias(".$self->alias.")",0);

} # End sub start

=head2 _stop

Mostly just a placeholder.

=cut

sub _stop :Cumulative {
  my ($kernel,  $self, $session) =
    @_[KERNEL, OBJECT,  SESSION];
    $self->Verbose("\n Socketfactory stopping \n\n" ,1);
}

=head2 _child

Just a placeholder.

=cut

sub _child {
  my ($kernel,  $self, $session) =
    @_[KERNEL, OBJECT,  SESSION];
}

=head2 _shutdown

Forcibly shutdown

=cut

sub _shutdown :Cumulative {
    my ($kernel,  $self, $session) =
    @_[KERNEL, OBJECT,  SESSION];
	# TODO, do some proper signal handling
	# especially reconnect on HUP and something on INT

	$self->Verbose('_shutdown: dropping controls',1, $self->controls);

	if ( defined( $self->controls ) )
	{
		foreach my $control ( values %{$self->controls} )
		{
			$kernel->post( $control->id() => '_shutdown' );
			delete(  $self->controls->{ $control->id }  );
		}
	}

	$self->Verbose("_shutdown: removing alarms",1,$kernel->alarm_remove_all() );

    $kernel->alias_remove( $self->alias );

    return("_shutdown ".$self->alias  );
}

=head2 PackRequest

This object method is used by transports to prepare a request for transmssion.

Currently the code is taking a lazy approach and using Perl's YAML and OIO->dump to
safely freeze and thaw the request/responses for Internet transport.
By standardizing these routines in the Base class, more elegant methods
may be transparently enabled in the future.

=cut
# TODO review XEP on this, esp version numbers and best practices.

sub PackRequest {
	my ($self, $request) = @_;
	my $dump = $request->dump();

	# Take out the Base to save space since we're ignore this at the other end.
	delete $dump->[1]{'Agent::TCLI::Base'};

	my $packed_request = freeze($dump);
	return($packed_request);
}

=head2 PackResponse

This object method is used by transports to prepare a reseponse for transmssion.
See PackRequest for more details.

=cut

#hmmm, right now there is no difference between PackRequest and PackResponse.
# I could typeglob it, but I think that will change soon.
sub PackResponse {
	my ($self, $response) = @_;
	my $dump = $response->dump();

	# Take out the Base to save space since we're ignore this at the other end.
	delete $dump->[1]{'Agent::TCLI::Base'};

	# freeze does not terminate the yaml
	my $packed_response = freeze($dump);
	return($packed_response);
}

=head2 UnackRequest

This object method is used by transports to unpack a request from transmssion.
See PackRequest for more details.

=cut

sub UnpackRequest {
	my ($self, $packed_request) = @_;
	$self->Verbose("UnpackRequest: $packed_request");

	my $request_array = thaw($packed_request);
	my %automethod_fields;

	foreach my $field ( keys %{ $request_array->[1]{'Agent::TCLI::Request'} } )
	{
		if ( $field =~ s/^get_// )
		{
			my $acc = 'get_'.$field;
			my $mut = 'set_'.$field;
			$automethod_fields{$mut} = $request_array->[1]{'Agent::TCLI::Request'}{ $acc }
				if (defined( $request_array->[1]{'Agent::TCLI::Request'}{ $acc } ));
			delete $request_array->[1]{'Agent::TCLI::Request'}{ $acc };
		}
	}

	my $request = Object::InsideOut->pump( $request_array );

	foreach my $field ( keys %automethod_fields )
	{
		$request->$field( $automethod_fields{$field} );
	}

	$request->verbose($self->verbose);
	$request->do_verbose($self->do_verbose);

	$self->Verbose("UnpackRequest: unpacked ".$request->dump(1) );

	return($request);
}

=head2 UnackResponse

This object method is used by transports to unpack a reseponse from transmssion.
See PackRequest for more details.

=cut

sub UnpackResponse {
	my ($self, $packed_response) = @_;
	$self->Verbose("UnpackResponse: $packed_response");

	my $response_array = thaw($packed_response);
	my %automethod_fields;

	foreach my $field ( keys %{ $response_array->[1]{'Agent::TCLI::Request'} } )
	{
		if ( $field =~ s/^get_// )
		{
			my $acc = 'get_'.$field;
			my $mut = 'set_'.$field;
			$automethod_fields{$mut} = $response_array->[1]{'Agent::TCLI::Request'}{ $acc }
				if (defined( $response_array->[1]{'Agent::TCLI::Request'}{ $acc } ));
			delete $response_array->[1]{'Agent::TCLI::Request'}{ $acc };
		}
	}

	my $response = Object::InsideOut->pump( $response_array );

	foreach my $field ( keys %automethod_fields )
	{
		$response->$field( $automethod_fields{$field} );
	}

	$response->verbose($self->verbose);
	$response->do_verbose($self->do_verbose);

	$self->Verbose("UnpackResponse: unpacked ".$response->dump(1) );

	return($response);
}

#sub SendResponse {
#	my ($kernel,  $self, $sender, $response) =
#  	  @_[KERNEL, OBJECT,  SENDER,      ARG1];
#	$self->Verbose("SendResponse: sender(".$sender.") Code(".$response->code.") \n");
#
#	my $request = $response->request;
#
#	# a good place to put response info is in the request.
#
#	# Should I just forward this on to a receive respose reoutine?
#	# Since this is local, and then it could be compatible
#	# with distributed testing?
#
#
#}
#
#sub SendChangeContext {
#	my ($kernel,  $self, $control ) =
#	  @_[KERNEL, OBJECT,    ARG0 ];
#	$self->Verbose("SendChangeContext: for control".$control->id());
#	# Context is in the control.....
#
#}
#
#sub GetRequestForInput {
#	my ($self,  $input ) = @_;
#	# This is used to package up a simple request easily
#
#	my $request = Agent::TCLI::Request->new({
#					'sender'	=> $self->alias,
#					'postback'	=> 'PostResponse',
#					'input'		=> $input,
#	});
#
#	return($request);
#
#}

=head2 not_authorized ( { parameters (see usage) } )

Checks to see if a id is authorized to use the transport.

=head3 Description

TODO

=head3 Usage

$self->not_authorized (
		user@example.com,
		qr(master|writer),  # optional regex for auth
		qr(xmpp),			# optional regex for protocol
		);

=cut

sub not_authorized {
	my ($self, $id, $auth, $protocol) = @_;
	$auth = defined($auth) ? $auth : qr(.*);
	$protocol = defined($protocol) ? $protocol : qr(.*);
	$self->Verbose("not_authorized: id(".$id.") auth($auth) protocol($protocol)",2);

	# create a blank user as kludge to simply debugging output.
	# This might be a slow memory exhaustion for lots of auth checks
	# if they are not getting cleand up properly
	my $authorized = 	Agent::TCLI::User->new(
			'id'		=> 'no one',
			'protocol'	=> 'none',
			'auth'		=> 'nil',
		);

	# only one should match on id and we get 0 on non id match,
	# so we'll just add through the whole loop of authorized peers
	# and add up the total.

	foreach my $pid ( @{$peers[$$self]} )
	{


		# user not_authorized returns something when not authorized.
	  	my $check = $pid->not_authorized ( {
	  		id	   		=>  $id,
			protocol 	=>  $protocol,
			auth		=>  $auth,
			} );
		$self->Verbose("not_authorized: Checked peer ".$pid->id." got ($check)",3);

	  	if ( !$check  )
	  	{
			# Set authorized to last matched user
			$authorized = $pid;
		}
	} #end foreach peer

	$self->Verbose("not_authorized:  ".$id." auth check got ".
		$authorized->id()." \n",1);

	return ($authorized)
} # End not_authorized

sub GetControl {
	my ($self, $control_id, $user, $user_protocol, $user_auth ) = @_;
	$self->Verbose($self->alias.":GetControl: id(".$control_id.") \n");

	my $user_id = ref($user) =~ /User/i ? $user->id : $user;

	my $auth_user = $self->not_authorized (
	  	$user_id,
	  	qr(.*),
	  	$user_protocol,
	  	);

	return (0) if ( $auth_user->auth eq 'nil' );

	$user_auth = $auth_user->auth unless defined($user_auth);

	if (defined( $controls[$$self]{$control_id} ))   #control in controls hash
	{
	  	$self->Verbose("GetControl: returning existing control for ".$control_id);
	}
	else   # new control
	{
		$controls[$$self]{$control_id} = Agent::TCLI::Control->new({
			'id'		=> $control_id,
			'user'		=> $auth_user,
			'auth'		=> $auth_user->auth(),
			'owner'		=> $self,
        	'verbose'	=> $self->verbose,
        	'do_verbose'=> $self->do_verbose,
        	%{$self->control_options},
    	});

		# This EXAMPLE shows how to set new control attributes.
		# $controls[$$self]{$control_id}->set_option($option);

	    $self->Verbose( "GetControl: New control ".$control_id." on input from ".$auth_user->id." \n",2);
	    $self->Verbose( "GetControl: self dump \n",4,$self);

    } # end if defined control

    return ( $controls[$$self]{$control_id} );

} # End GetControl

sub DeleteControl {
	my ($self, $control_id ) = @_;
	$self->Verbose($self->alias.":GetControl: id(".$control_id.") \n");

	if (defined( $controls[$$self]{$control_id} ))   #control in controls hash
	{
	  	$self->Verbose("DeleteControl: deleting control for ".$control_id);
	  	delete($controls[$$self]{$control_id});
	}
	else   # not there
	{
	  	$self->Verbose("DeleteControl: control ".$control_id." not found");
    } # end if defined control

  return ( 1 );

} # End DeleteControl


=head3 Set

This POE event handler is may be used by a Transport to enable a Package
to set attributes in the Transport. It currently is not filtering
out anything, so if something should not be accessible, either the Transport
needs to implement its own Set, or the Package should apply necessary filters.

B<Set> takes a hash of attribute => value pairs, and the Request object as arguments.

=cut

sub Set {
	my ($kernel,  $self, $params, $request) =
	  @_[KERNEL, OBJECT,    ARG0,     ARG1];
    $self->Verbose("Set: params ",1,$params);

	my $txt = '';
	my $code;

	# TODO a way to unset/restore defaults....

	# lets see how it goes....
	foreach my $attr ( keys %{$params} )
	{
		# special case for verbose.
		$attr = 'verbose' if ($attr =~ qr(_verbose));


		eval { $self->$attr( $params->{$attr} ) };

		if( $@ )
		{
			$self->Verbose("Set: self->".$attr.'('.$params->{$attr}.' ) got ('.$@.') ');
			$txt = "Invalid: $attr => ".$params->{$attr}." !";
			$code = 400;
		}
		else
		{
			$txt = "Set: $attr =>  ".$params->{$attr}."  ";
			$code = 200;
		}

		if ($request)
		{
			$self->Verbose('Set: responding txt('.$txt.') code('.$code." )",2);
			$request->Respond($kernel, $txt, $code);
		}
	}
}

=head3 Show

This POE event handler is may be used by a Transport to enable a Package
to show current settings in the Transport. It currently is not filtering
out anything, so if something should not be shown, either the Transport
needs to implement its own Show, or the Package should apply necessary filters.

B<Show> takes the attribute to show and the Request object as arguments.

=cut

sub Show {
	my ($kernel,  $self, $attr, $request) =
	  @_[KERNEL, OBJECT,  ARG0,     ARG1];
    $self->Verbose("Show: $attr ",1);

	my $txt = '';
	my ($code, $value);

	if ($attr eq 'peers')
	{
		# loop over the users
		foreach my $peer ( @{$self->peers} )
		{
			$txt .= "\nid: ".$peer->id."\nprotocol: ".$peer->protocol.
				"\nauth: ".$peer->auth."\npassword: ******\n";
			$code = 200;
		}
	}
	elsif ($attr eq 'controls')
	{
		# loop over the controls
		foreach my $control ( keys %{$self->controls} )
		{
			$txt .= "\nid: ".$control->id."\n";
			$code = 200;
		}
	}
	else
	{
		# lets see how it goes....
		eval { $value = $self->$attr };

		if( $@ )
		{
			$self->Verbose("Show: self->$attr got (".$@.') ');
			$txt = "Invalid $attr : $@ !";
			$code = 400;
		}
		elsif ( ref($value) )
		{
			$txt = "$attr is not a scalar. Dumping: \n";
			$txt .= pp($value);
			$code = 200;
		}
		else
		{
			$txt = "$attr => $value ";
			$code = 200;
		}
	}

	if ($request)
	{
		$self->Verbose('Show: responding txt('.$txt.') code('.$code." )",3);
		$request->Respond($kernel, $txt, $code);
		return;
	}
	# What do we do if there is no request?
}

=head3 _default

This POE event handler is used to catch wayard calls to unavailable states. If
verbose is on, it makes it rather obvious in the logs that an event was not
handled.

=cut

sub _default {
  my ($kernel,  $self, ) =
    @_[KERNEL, OBJECT, ];
 	my $oops = "\n\n\n".
	"\t  OOOO      OOOO    PPPPPP    SSSSSS    ##  \n".
	"\t OO  OO    OO  OO   PP   PP  SS         ##  \n".
	"\tOO    OO  OO    OO  PP   PP  SS         ##  \n".
	"\tOO    OO  OO    OO  PPPPPP    SSSSSS    ##  \n".
	"\tOO    OO  OO    OO  PP             SS   ##  \n".
	"\t OO  OO    OO  OO   PP             SS       \n".
	"\t  OOOO      OOOO    PP        SSSSSS    ##  \n";
	$self->Verbose($oops);
	$self->Verbose("\n\nDefault caught an unhandled $_[ARG0] event.\n");
	$self->Verbose("The $_[ARG0] event was given these parameters:");
	$self->Verbose("ARG1 dumped",1,$_[ARG1]) if defined($_[ARG1]);
	$self->Verbose("ARG2 dumped",1,$_[ARG2]) if defined($_[ARG2]);

	return (0);
}

1;

#__END__

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

SHOULDS and MUSTS are currently not enforced.

New commands could clobber old ones under certain circumstances.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
