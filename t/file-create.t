#!/usr/bin/perl

use Test::More;
use Test::RDF;
use File::Util;
use RDF::Trine;
use File::Temp qw/tempfile cleanup/;

use_ok('RDF::Trine::Store::File');

my ($fh, $filename) = tempfile();

my $store = RDF::Trine::Store::File->new($filename);

ok($store, 'Store object OK');

$store->add_statement(RDF::Trine::Statement->new(
						 RDF::Trine::Node::Resource->new('http://example.org/a'),
						 RDF::Trine::Node::Resource->new('http://example.org/b'),
						 RDF::Trine::Node::Resource->new('http://example.org/c')
						));

is($store->size, 1, 'Store has one statement');

my($f) = File::Util->new();

{
  my($content) = $f->load_file($filename);

  is_valid_rdf($content, 'ntriples', 'Content is valid N-Triples');

  is_rdf($content, 'ntriples', '<http://example.org/a> <http://example.org/b> <http://example.org/c> .', 'ntriples', 'Content is correct');
}

$store->add_statement(RDF::Trine::Statement->new(
						 RDF::Trine::Node::Resource->new('http://example.org/a'),
						 RDF::Trine::Node::Resource->new('http://example.org/d'),
						 RDF::Trine::Node::Resource->new('http://example.org/e')
						));

$store->add_statement(RDF::Trine::Statement->new(
						 RDF::Trine::Node::Resource->new('http://example.org/a'),
						 RDF::Trine::Node::Resource->new('http://example.org/d'),
						 RDF::Trine::Node::Literal->new('Dahut')
						));

is($store->size, 3, 'Store has three statements');

{
  my($content) = $f->load_file($filename);
  is_valid_rdf($content, 'ntriples', 'Content is valid N-Triples');

#  is_rdf($content, 'ntriples', '<http://example.org/a> <http://example.org/b> <http://example.org/c> .', 'ntriples', 'Content is correct');
}

done_testing;
