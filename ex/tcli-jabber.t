#!/usr/bin/perl
# $Id: tcli-jabber.t 13 2007-03-23 23:34:46Z hacker $
use lib '../lib','/home/hacker/lib/perl5/site_perl/5.8.3/','/home/hacker/lib/perl5/5.8.3/','/root/NetSecVet/lib/';

use Test::Jabber::Simple no_plan;

use Jabber::Lite;
use Getopt::Long;
#use File::Slurp;
#use XML::Simple;
use Carp;
use Data::Dumper;

# process options
my ($delay,$verbose,$buddy,$username,$password,$host);
eval { GetOptions (
		"delay:i"		=> \$delay,
  		"buddy:s"		=> \$buddy,
  		"username:s"	=> \$username,
  		"password:s"	=> \$password,
  		"host:s"		=> \$host,
  		"verbose+"		=> \$verbose,
)};
if($@) {die "ERROR: $@";}

$verbose = 0 unless defined($verbose);
$host = 'testing.erichacker.com' unless defined($host);
$delay = 3 unless defined($delay);

# bot that is being tested
$buddy = 'testy2@testing.erichacker.com' unless defined($buddy);
# jabber username/password to log in with to order bot to attack
$username = 'testy1' unless defined($username);
$password = 'testy1' unless defined($password);

# Initialize jabber bot communications
my $jc = Jabber::Lite->new(debug=>$verbose);

jabber_connect_ok($jc, { Host=>$host }, "Connecting ");
jabber_authenticate_ok($jc, {Username=>$username,Password=>$username,Resource=>'tester'}, "Authenticating ");

# Clear out any previous leftover context
jabber_ask_message_like($jc,
	{to=>$buddy,
	msg=>'/'},
	qr(exiting),
	"clearing context ");

jabber_get_message_like($jc,
	qr(Context),
	"clearing context ");

jabber_ask_message_like($jc,
	{to=>$buddy,
	msg=>'meganat'},
	qr(meganat),
	"setting meganat context ");

jabber_ask_message_like($jc,
	{to=>$buddy,
	msg=>"add target=10.0.0.1"},
	qr(1/1 addresses added.),
	" set meganat for 10.0.0.1 ");

jabber_ask_message_like($jc,
	{to=>$buddy,
	msg=>'/'},
	qr(exiting),
	"clearing context ");

jabber_get_message_like($jc,
	qr(Context),
	"clearing context ");

# put us in the http context
jabber_ask_message_like($jc,
	{to=>$buddy,
	msg=>"http"},
	qr(http),
	" send http ");

jabber_ask_message_like($jc,
	{to=>$buddy,
 	msg=>"tget url=http://testing.erichacker.com/404.html resp=404,400 id=42"},
	qr(ok 42),
	" check for good 404 at count 42");

jabber_ask_message_like($jc,
	{to=>$buddy,
 	msg=>"tget url=http://testing.erichacker.com/ resp=200 id=43"},
	qr(ok 43),
	" check for good 200 at count 43");

# Exit out of http context
jabber_ask_message_like($jc,
	{to=>$buddy,
	msg=>'exit'},
	qr(exiting),
	"exiting context http");
jabber_get_message_like($jc,
	qr(Context),
	"clearing context ");

#remove meganat from bot
jabber_ask_message_like($jc,
	{to=>$buddy,
	msg=>"meganat remove 10.0.0.1 "},
	qr(1/1 addresses deleted.),
	" remove meganat for 10.0.0.1 ");

jabber_disconnect_ok($jc, "Disconnecting");

