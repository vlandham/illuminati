package Zan::RPC;

use 5.008008;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use JSON::RPC::Client;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Zan::RPC ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new {
	my $class = shift;
	my $serviceURL = shift;
	my $authToken = shift;

	# Build the service URL from the passed in installation path
	if ($serviceURL !~ /\.php/i) {
		$serviceURL = $serviceURL . "/zancore/plugins/rpc/mediateRemote.php";
	}

	my $self = {
		serviceURL => $serviceURL,
		authToken => $authToken
	};

	return bless($self, $class);
}

sub call {
	my $self = shift;
	my $methodID = shift;
	my @params;

	while (my $param = shift) {
		push(@params, $param);
	}

	my $client = new JSON::RPC::Client;

	my $obj = {
		_zan_rpcAuthToken => $self->{authToken},
		_zan_rpcClientVersion => "1.0",
		method => $methodID,
		params => \@params
	};

	my $res = $client->call($self->{serviceURL}, $obj);

	if ($res) {
		if ($res->is_error) {
			croak("RPC Error: ", $res->error_message);
		} else {
			return $res->result;
		}
	} else {
		croak("Invalid server response: ", $client->status_line);
	}
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

 Zan::RPC - Module to enable RPC calls against a Zan Modules installation
 
=head1 DEPENDENCIES

 Zan::RPC depends on the JSON and JSON::RPC modules.

=head1 SYNOPSIS

 use Zan::RPC;
 $rpc = new Zan::RPC("<url to zan modules>", "<auth token from zan modules>");
 $result = $rpc->call("module.method.function", [ "arg1", "arg2"]);
 print $result . "\n";


 The URL to zan modules should be the base URL of the installation.  For example,
 if the URL to the login page is:
 http://example.com/zanmodules/_site/index.php

 The url passed to the Zan::RPC constructor should be:
 http://example.com/zanmodules/


=head1 DESCRIPTION

 This module provides methods for making remote procedure calls against a Zan Modules
 installation.  For calls that require authentication, you will have to create an
 authentication token from within Zan Modules.


=head1 AUTHOR

 Zan Consulting, LLC
 zanmodules@zanconsulting.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Zan Consulting LLC

All rights reserved.


=cut
