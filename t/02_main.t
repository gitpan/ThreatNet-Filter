#!/usr/bin/perl -w

# Load test the ThreatNet::Filter module

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}

use Test::More tests => 28;
use ThreatNet::Message::IPv4;

my $Message = ThreatNet::Message::IPv4->new( '123.123.123.123' );
isa_ok( $Message, 'ThreatNet::Message' );





#####################################################################
# Tests for ThreatNet::Filter

use ThreatNet::Filter;
{
	my $Filter = ThreatNet::Filter->new;
	isa_ok( $Filter, 'ThreatNet::Filter' );
	is( $Filter->keep(), undef, '->keep() returns undef' );
	is( $Filter->keep(undef), undef, '->keep(undef) returns undef' );
	is( $Filter->keep($Message), 1, '->keep(msg) returns true' );
}





#####################################################################
# Tests for ThreatNet::Filter::Null

use ThreatNet::Filter::Null;
{
	my $Filter = ThreatNet::Filter::Null->new;
	isa_ok( $Filter, 'ThreatNet::Filter::Null' );
	isa_ok( $Filter, 'ThreatNet::Filter' );
	is( $Filter->keep(), undef, '->keep() returns undef' );
	is( $Filter->keep(undef), undef, '->keep(undef) returns undef' );
	is( $Filter->keep($Message), '', '->keep(msg) returns false' );
}





#####################################################################
# Tests for ThreatNet::Filter::ThreatCache

use ThreatNet::Filter::ThreatCache;
{
	my $Filter = ThreatNet::Filter::ThreatCache->new;
	isa_ok( $Filter, 'ThreatNet::Filter::ThreatCache' );
	isa_ok( $Filter, 'ThreatNet::Filter' );
	is( $Filter->keep(), undef, '->keep() returns undef' );
	is( $Filter->keep(undef), undef, '->keep(undef) returns undef' );

	# For the same message, it should be kept the first time and
	# rejected the second time
	is( $Filter->keep($Message), 1, '->keep(msg) returns true the first time' );
	is( $Filter->keep($Message), '', '->keep(msg) returns false the second time' );
}





#####################################################################
# Tests for ThreatNet::Filter::Chain

use ThreatNet::Filter::Chain;
{
	my $counter1 = 0;
	my $counter2 = 0;
	my $Filter = ThreatNet::Filter::Chain->new(
		ThreatNet::Filter->new,
		My::Filter1->new,
		ThreatNet::Filter::ThreatCache->new,
		My::Filter2->new,
		ThreatNet::Filter::Null->new,
		);
	isa_ok( $Filter, 'ThreatNet::Filter::Chain' );
	isa_ok( $Filter, 'ThreatNet::Filter' );
	is( $Filter->keep(), undef, '->keep() returns undef' );
	is( $Filter->keep(undef), undef, '->keep(undef) returns undef' );

	# Throw some messages at the filter chain
	my @messages = (
		ThreatNet::Message::IPv4->new( '1.2.3.4' ),
		ThreatNet::Message::IPv4->new( '1.2.3.5' ),
		ThreatNet::Message::IPv4->new( '1.2.3.4' ),
		);
	foreach my $msg ( @messages ) {
		isa_ok( $msg, 'ThreatNet::Message' );
		is( $Filter->keep($msg), '', '->keep(msg) always returns false' );
	}

	is( $counter1, 3, '$counter1 ends with the expected value 3' );
	is( $counter2, 2, '$counter2 ends with the expected value 2' );

	### Test filters
	package My::Filter1;
	use base 'ThreatNet::Filter';
	sub keep { $counter1++; 1 }

	package My::Filter2;
	use base 'ThreatNet::Filter';
	sub keep { $counter2++; 1 }
}

1;
