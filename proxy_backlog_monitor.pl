use strict;
use warnings;

use vars qw($VERSION %IRSSI);
$VERSION = '20120421a';
%IRSSI = (
	name		=> 'Proxy Monitor',
	authors		=> 'Iain Cuthbertson',
	contact		=> 'iain.cuthbertson@idophp.co.uk',
	url 		=> 'http://idophp.co.uk/',
	license		=> 'GPL',
	description	=> 'Monitor conntection/disconnect from proxy clients and send'
				. 'the backlog',
);
use Irssi qw(signal_add);

use File::Path qw(make_path remove_tree);


sub proxy_disconnect
{
	Irssi::settings_set_str('proxy_logging', 1);

	my $network = $_[0]->{server}->{tag};

	print '+-- [proxy monitor] - started for: ' . $_[0]->{server}->{tag};
}

sub proxy_connect
{
	Irssi::settings_set_str('proxy_logging', 0);

	my $network = $_[0]->{server};

	print '+-- [proxy monitor] - stopped for: ' . $network->{tag};

	send_backlog($network);
	
	# Disabled backlog wiping until completely working
	# wipe_backlog($network);
}

sub log_self_message
{
	
}

sub log_public_message
{
	my $loggingActive = Irssi::settings_get_str('backlog_path');
	
	if ($loggingActive)
	{
		my $network = $_[0]->{tag};
		my $channel = $_[4];
		my $nick = $_[2];
		my $msg = $_[1];
		
		my $backlogPath = Irssi::settings_get_str('backlog_path');
		my $backlogDir = $backlogPath . '/' . $network;
	
		unless(-d $backlogDir)
		{
			mkdir $backlogDir or die $!;
		}

		my $backlogFile = $backlogDir . '/' . $channel . '.log';
	
		open (BACKLOG, '>>' . $backlogFile);
		print BACKLOG "(" . time() . ") <" . $nick . "> " . $msg . "\n";
		close (BACKLOG); 
	}
	
}

sub send_backlog
{
	my $network = $_[0];
	my $networkName = $network->{tag};
	#use Data::Dumper;
	#print Dumper($network); return 1;
	
	my $backlogPath = Irssi::settings_get_str('backlog_path');
	my $backlogDir = $backlogPath . '/' . $networkName;
	
	if (-d $backlogDir)
	{
		print '+-- [proxy monitor] - backlog for network: ' . $networkName . ' [START]';
		
		opendir (DIR, $backlogDir) or die $!;
	
		while (my $channelFile = readdir(DIR))
		{
			my $backlogFile = $backlogDir . '/' . $channelFile;
			my $channelName = substr($channelFile, 0, -4);

			if (-f $backlogFile)
			{
				print '--- Sending content from ' . $networkName . '/' . $channelFile;
				# $network->print($channelName, 'hello ' . $channelName, MSGLEVEL_PUBLIC);
			}
		}
		print '+-- [proxy monitor] - backlog for network: ' . $networkName . ' [END]';
	}
}

sub wipe_backlog
{
	my $network = $_[0];
	
	my $backlogPath = Irssi::settings_get_str('backlog_path');
	my $backlogDir = $backlogPath . '/' . $network;
	
	if (-d $backlogDir)
	{
		remove_tree($backlogDir);
		
		print '+-- [proxy monitor] - backlog removed for network: ' .$network;
	}
}

Irssi::settings_add_str('proxy_monitor', 'backlog_path', '/home/iain/.irssi/proxy_monitor');

Irssi::settings_add_str('proxy_monitor', 'proxy_logging', 1);

Irssi::signal_add_last('proxy client disconnected', 'proxy_disconnect');
Irssi::signal_add_last('proxy client connected', 'proxy_connect');

Irssi::signal_add_last('send text', 'log_self_message');
Irssi::signal_add_last('message public', 'log_public_message');
#Irssi::signal_add_last('message private', 'log_private_message');
#Irssi::signal_add_last('', '');
#Irssi::signal_add_last('', '');
#Irssi::signal_add_last('', '');
#Irssi::signal_add_last('', '');
#Irssi::signal_add_last('', '');
#Irssi::signal_add_last('', '');
#Irssi::signal_add_last('', '');

