#!/usr/bin/perl -w 
# vim:filetype=perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#
# basic.t
# -------
# Tests that;
#

use Test::More qw/no_plan/;
use Test::Exception;

use strict;
use Data::Dumper;
our %opt;
BEGIN { map { $opt{$_}=1 if s/^-// } @ARGV; }
use constant DEBUG => (exists $opt{d} ? 1 : 0);
local $SIG{__WARN__} = sub { diag "[warn] ", @_; };

use FindBin qw/$Bin/;

# Usefull test subs for the schema objs
#=============================================================================

our %ATTRIBUTES;
$ATTRIBUTES{field} = [qw/
name
order
data_type
default_value
size
is_primary_key
is_unique
is_nullable
is_foreign_key
is_auto_increment
/];

sub test_field {
	my ($fld,$test) = @_;
	die "test_field needs a least a name!" unless $test->{name};
	my $name = $test->{name};
	is $fld->name, $name, "$name - Name right";

	foreach my $attr ( @{$ATTRIBUTES{field}} ) {
		if ( defined(my $ans = $test->{$attr}) ) {
			if ( $attr =~ m/^is_/ ) {
				ok $fld->$attr, " $name - $attr true";
			}
			else {
				is $fld->$attr, $ans, " $name - $attr = '$ans'";
			}
		}
		else {
			ok !$fld->$attr, "$name - $attr not set";
		}
	}
}

# TODO test_constraint, test_index

# Testing 1,2,3,4...
#=============================================================================

use SQL::Translator;
use SQL::Translator::Schema::Constants;

# Parse the test XML schema
our $obj;
$obj = SQL::Translator->new(
	debug          => DEBUG,
	show_warnings  => 1,
	add_drop_table => 1,
);
my $testschema = "$Bin/data/xml/schema-basic.xml";
die "Can't find test schema $testschema" unless -e $testschema;
my $sql = $obj->translate(
	from     => "SqlfXML",
	to       =>"MySQL",
	filename => $testschema,
);
print $sql;
#print "Debug:", Dumper($obj) if DEBUG;

# Test the schema objs generted from the XML
#
my $scma = $obj->schema;
my @tblnames = map {$_->name} $scma->get_tables;
is_deeply( \@tblnames, [qw/Basic/], "tables");

# Basic
my $tbl = $scma->get_table("Basic");
is $tbl->order, 1, "Basic->order";
is_deeply( [map {$_->name} $tbl->get_fields], [qw/id title description email/]
													, "Table Basic's fields");
test_field($tbl->get_field("id"),{
	name => "id",
	order => 1,
	data_type => "int",
	size => 10,
	is_primary_key => 1,
	is_auto_increment => 1,
});
test_field($tbl->get_field("title"),{
	name => "title",
	order => 2,
	data_type => "varchar",
	default_value => "hello",
	size => 100,
});
test_field($tbl->get_field("description"),{
	name => "description",
	order => 3,
	data_type => "text",
	is_nullable => 1,
});
test_field($tbl->get_field("email"),{
	name => "email",
	order => 4,
	data_type => "varchar",
	size => 255,
	is_unique => 1,
});

my @indices = $tbl->get_indices;
is scalar(@indices), 1, "Table basic has 1 index";

my @constraints = $tbl->get_constraints;
is scalar(@constraints), 2, "Table basic has 2 constraints";
my $con = shift @constraints;
is $con->table, $tbl, "Constaints table right";
is $con->name, "", "Constaints table right";
is $con->type, PRIMARY_KEY, "Constaint is primary key";
is_deeply [$con->fields], ["id"], "Constaint fields";
$con = shift @constraints;
is $con->table, $tbl, "Constaints table right";
is $con->type, UNIQUE, "Constaint UNIQUE";
is_deeply [$con->fields], ["email"], "Constaint fields";