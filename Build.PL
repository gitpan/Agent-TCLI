use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Agent-TCLI',
    license             => 'perl',
    dist_author         => 'Eric Hacker <hacker@cpan.org>',
    dist_abstract		=> 'Transactional Contextual Line Interface Agent',
    dist_version_from   => 'lib/Agent/TCLI.pm',
    requires => {
		'Data::Dump' 	            => '0',
#		'TimeDate'					=> '1.16',
		'Date::Parse'				=> '1.16',
		'FormValidator::Simple'		=> '0',
		'Getopt::Lucid'             => '0.16',
#		'Scalar::List::Utils'        => '1.18',
		'Scalar::Util' 		    	=> '1.18',
		'Module::Build'				=> '0',
		'Net::Jabber'		        => 'undef',
		'Net::XMPP'		   	     	=> '1.02',
		'NetAddr::IP'		        => '3',
		'Object::InsideOut'			=> '3.07',

		'Test::Simple'              => '0.62',
		'YAML::Syck'				=> '0'
    	},
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();


