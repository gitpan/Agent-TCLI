#!/usr/bin/perl

use warnings;
use strict;
#use lib ('blib/lib');
use Test::More qw(no_plan);

sub VERBOSE () { 0 }

use Getopt::Lucid qw(:all);

my ($opt, $verbose,$domain,$username,$password,$host, $poe_td, $poe_te);

eval {$opt = Getopt::Lucid->getopt([
		Param("domain"),
		Param("username|u"),
		Param("password|p"),
		Param("host"),
		Counter("poe_debug|d"),
		Counter("poe_event|e"),
		Param("xmpp_debug|x"),
		Counter("verbose|v"),
	])};
if($@) {die "ERROR: $@";}

$verbose = $opt->get_verbose ? $opt->get_verbose : VERBOSE;

# xmpp username/password to log in with
$username = $opt->get_username ? $opt->get_username : 'target';
$password = $opt->get_password ? $opt->get_password : 'target';
$domain = $opt->get_domain ? $opt->get_domain : 'example.com';
$host = $opt->get_host ? $opt->get_host : 'example.com';
$poe_td = $opt->get_poe_debug;
$poe_te = $opt->get_poe_event;

sub POE::Kernel::TRACE_DEFAULT  () { $poe_td }
sub POE::Kernel::TRACE_EVENTS  () { $poe_te }
use POE;
use Agent::TCLI::Transport::Test;
use Agent::TCLI::Transport::Test::Testee;
use Agent::TCLI::Transport::XMPP;
use Agent::TCLI::Package::XMPP;
use Agent::TCLI::Package::Tail;

# Need to set up transport to talk to other bots

my @users = (
	# If attacker is to be direcetded by user target, then target has to be a user.
	Agent::TCLI::User->new(
		'id'		=> 'target@'.$domain,
		'protocol'	=> 'xmpp',
		'auth'		=> 'master',
	),
	Agent::TCLI::User->new(
		'id'		=> 'user1@'.$domain,
		'protocol'	=> 'xmpp',
		'auth'		=> 'master',
	),
	Agent::TCLI::User->new(
		'id'		=> 'user2@'.$domain,
		'protocol'	=> 'xmpp',
		'auth'		=> 'master',
	),
	Agent::TCLI::User->new(
		'id'		=> 'conference_room@conference'.$doamin,
		'protocol'	=> 'xmpp_groupchat',
		'auth'		=> 'master',
	),
);

# Packages for XMPP

# Within test scripts, we use diag() to output verbose messages
# to ensure we don't mess up the Test::Harness processing.
my @packages = (
	# We need the transport controller package to shut down the transport at the
	#end of hte testing.
	Agent::TCLI::Package::XMPP->new(
	    'verbose'    => \$verbose ,
		'do_verbose'	=> sub { diag( @_ ) },
	),
	Agent::TCLI::Package::Tail->new({
		'verbose'		=> \$verbose,
		'do_verbose'	=> sub { diag( @_ ) },
	}),
);

# Need a transport to deliver the tests to remote hosts
Agent::TCLI::Transport::XMPP->new(
    'jid'		=> Net::XMPP::JID->new($username.'@'.$domain.'/test'),
    'jserver'	=> $host,
	'jpassword'	=> $password,
	'peers'		=> \@users,

	'xmpp_debug' 		=> 0,
	'xmpp_process_time'	=> 1,

    'verbose'    	=> $verbose,        # Verbose sets level
	'do_verbose'	=> sub { diag( @_ ) },

    'control_options'	=> {
	    'packages' 		=> \@packages,
     },
);

my $test_master = Agent::TCLI::Transport::Test->new({

    'verbose'   	=> \$verbose,        # Verbose sets level
	'do_verbose'	=> sub { diag( @_ ) },

    'control_options'	=> {
	    'packages' 		=> \@packages,
    },

});

# Set up the local test
my $target = Agent::TCLI::Transport::Test::Testee->new(
	'test_master'	=> $test_master,
	'addressee'		=> 'self',
);

# Set up the remote test
my $attacker = Agent::TCLI::Transport::Test::Testee->new({
	'test_master'	=> $test_master,
	'addressee'		=> 'attacker@'.$domain,
	'transport'		=> 'transport_xmpp',  # The default POE Session alias
	'protocol'		=> 'XMPP',

	'verbose'		=> \$verbose,
	'do_verbose'	=> sub { diag( @_ ) },
});

$target->is_code('tail file add file /var/www/logs/access_log',200, 'added /var/www/logs/access_log');
$target->is_code('tail test add like 200',100, 'added test like 200');
$target->is_code('',200, 'passed test like 200');
$attacker->is_code('http tget url=http://target'.$domain.' resp=200',200,"attacker tget 200");
$target->is_code('tail test add like 404',100, 'added test like 404');
$target->is_code('',200, 'passed test like 404');
$attacker->is_code('http tget url=http://target'.$domain.'/404.html resp=404',200,"attacker tget 404");

$attacker->is_code('http tget url=http://target'.$domain.'  resp=200',200,"attacker tget 200");

$target->like_body( 'root',qr(Context now: ), "Root ok");

# maks sure to queue shutting down the transport or else the script will not stop.
$target->is_code('xmpp shutdown',200, "Shutdown xmpp");

# Though tests will start during building of the tests, POE isn't fully running
# and all tests will not complete until the master run is called. This routine
# does more than just call POE::Kernel->run, so don't attempt to substitute that
# here.
$test_master->run;

