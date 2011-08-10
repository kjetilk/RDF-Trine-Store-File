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

my($f) = File::Util->new();

my($content) = $f->load_file(FH => $fh);

is_valid_rdf($content, 'ntriples', 'Content is valid N-Triples');

done_testing;
