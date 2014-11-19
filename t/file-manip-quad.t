#!/usr/bin/perl

use strict;
use Test::More;
use Test::RDF;
use RDF::Trine qw(statement iri literal);
use File::Temp qw/tempfile cleanup/;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init( { level   =>  $TRACE} ) if $ENV{TEST_VERBOSE};

use_ok('RDF::Trine::Store::File::Quad');

my ($fh, $filename) = tempfile(EXLOCK => 0);

my $store = RDF::Trine::Store::File::Quad->new($filename);

ok($store, 'Store object OK');

$store->add_statement(statement(
						 iri('http://example.org/a'),
						 iri('http://example.org/b'),
						 iri('http://example.org/c'),
						 iri('http://example.org/g')
						));

is($store->size, 1, 'Store has one statement according to size');

is($store->count_statements(undef, undef, undef, undef), 1, 'Store has one statement according to count');

my $first_etag = $store->etag;

like($first_etag, qr/\w{32}/, 'Etag is 32 chars long, only hex');

note "Sleep one second to ensure new etag";
sleep 1;

close $fh;


{
# Now, we open the file ourselves in addition to the module
	local $/ = undef;
	open my ($FH), $filename;
	my $content  = <$FH>;
	close $FH;


  is_valid_rdf($content, 'nquads', 'Content is valid N-Quads');

  is_rdf($content, 'nquads', '<http://example.org/a> <http://example.org/b> <http://example.org/c> .', 'turtle', 'Content is correct');
}

$store->add_statement(statement(
						 iri('http://example.org/a'),
						 iri('http://example.org/d'),
						 iri('http://example.org/e'),
						 iri('http://example.org/g')
						));

$store->add_statement(statement(
						 iri('http://example.org/a'),
						 iri('http://example.org/d'),
						 literal('Dahut'),
						 iri('http://example.org/f')
						));
$store->add_statement(statement(
						 iri('http://example.org/a'),
						 iri('http://example.org/d'),
						 literal('Dahut', 'en'),
						 iri('http://example.org/g')
						));

is($store->size, 4, 'Store has four statements');

is($store->count_statements(
			    iri('http://example.org/a'),
			    iri('http://example.org/d'),
			    undef, undef), 3, 'Three statements with object unbound');

is($store->count_statements(
			    iri('http://example.org/a'),
			    iri('http://example.org/d'),
			    undef, 
				 iri('http://example.org/g'),
					), 2, 'Two statements with object unbound');

is($store->count_statements(
			    undef,
			    iri('http://example.org/d'),
			    literal('Dahut', 'en'),
				 undef),
   1, '1 statement with object bound to lang literal');

my $second_etag = $store->etag;

like($second_etag, qr/\w{32}/, 'Etag is 32 chars long, only hex');

isnt($first_etag, $second_etag, 'Etags differ');

{
	local $/ = undef;
	open my ($FH), $filename;
	my $content  = <$FH>;
	close $FH;

  is_valid_rdf($content, 'nquads', 'Content is valid N-Quads');

#  is_rdf($content, 'nquads', '<http://example.org/a> <http://example.org/b> <http://example.org/c> .', 'nquads', 'Content is correct');
}

$store->remove_statement(statement(
						 iri('http://example.org/a'),
						 iri('http://example.org/d'),
						 iri('http://example.org/e'),
						 iri('http://example.org/g')
						));

is($store->size, 3, 'Store has 3 statements after single remove');

is($store->size, $store->count_statements(undef, undef, undef, undef), 'count and size are equal');

$store->remove_statements(
			  iri('http://example.org/a'),
			  iri('http://example.org/d'),
			  undef,
			  iri('http://example.org/f')
			 );

is($store->size, 2, 'Store has one statement after match-remove');

$store->remove_statements(
			  iri('http://example.org/a'),
			  iri('http://example.org/d'),
			  undef, undef);

is($store->size, 1, 'Store has one statement after match-remove');

$store->nuke;

ok(! -e $filename, 'File is gone');
sleep(1); # to allow the FH from the previous ok() to be flushed


{
  my $store2 = RDF::Trine::Store::File::Quad->new_with_string('File::Quad;' . $filename);

  ok($store2, 'Store with string config object OK');

  $store2->add_statement(statement(
						    iri('http://example.org/a'),
						    iri('http://example.org/b'),
						    iri('http://example.org/c'),
							 iri('http://example.org/h')
						   ));

  is($store2->size, 1, 'Store with string config has one statement according to size');

  $store2->nuke;

  ok(! -e $filename, 'File with string config is gone');
}

done_testing;
