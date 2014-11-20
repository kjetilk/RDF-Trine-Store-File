#!/usr/bin/perl

use Test::More;
use Log::Log4perl qw(:easy);
use RDF::Trine qw(iri variable);

Log::Log4perl->easy_init( { level   =>  $TRACE} ) if $ENV{TEST_VERBOSE};

use_ok('RDF::Trine::Store::File');

my $store = RDF::Trine::Store::File->temporary_store;

isa_ok($store, 'RDF::Trine::Store::File');

note 'Triple regexps';
{
	my $regex = $store->_search_regexp(variable('s'),
												  iri('http://example.org/b'),
												  iri('http://example.org/c')
												 );
	is($regex, '((?:<.*?>|_:\w+?) <http://example.org/b> <http://example.org/c> \.\n)', 'Subject variable matches');
}

{
	my $regex = $store->_search_regexp(iri('http://example.org/a'),
												  iri('http://example.org/d'),
												  variable('o')
												 );
	is($regex, '(<http://example.org/a> <http://example.org/d> .+ \.\n)', 'object variable matches');
}

{
	my $regex = $store->_search_regexp(iri('http://example.org/a'),
												  variable('p'),
												  variable('o')
												 );
	is($regex, '(<http://example.org/a> <.*?> .+ \.\n)', 'predicate and object variable matches');
}

note 'Quad regexps';

{
	my $regex = $store->_search_regexp(variable('s'),
												  iri('http://example.org/b'),
												  iri('http://example.org/c'),
												  iri('http://example.org/d')
												 );
	is($regex, '((?:<.*?>|_:\w+?) <http://example.org/b> <http://example.org/c> <http://example.org/d> ?\.\n)', 'Subject variable matches');
}

{
	my $regex = $store->_search_regexp(
												  iri('http://example.org/a'),
												  iri('http://example.org/d'),
												  variable('o'),
												  iri('http://example.org/c')
												 );
	is($regex, '(<http://example.org/a> <http://example.org/d> .+ <http://example.org/c> ?\.\n)', 'object variable matches');
}

{
	my $regex = $store->_search_regexp(
												  variable('s'),
												  iri('http://example.org/a'),
												  iri('http://example.org/d'),
												  variable('g'),
												 );
	is($regex, '((?:<.*?>|_:\w+?) <http://example.org/a> <http://example.org/d> (?:(?:<.*?>|_:\w+?))? ?\.\n)', 'subject and graph variable matches');
}

{
	my $regex = $store->_search_regexp(
												  iri('http://example.org/a'),
												  variable('p'),
												  variable('o'),
												  variable('g')
												 );
	is($regex, '(<http://example.org/a> <.*?> .+ (?:(?:<.*?>|_:\w+?))? ?\.\n)', 'predicate, object and graph variable matches');
}


$store->nuke;

done_testing;
