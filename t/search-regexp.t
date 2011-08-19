#!/usr/bin/perl

use Test::More;

use_ok('RDF::Trine::Store::File');

my $store = RDF::Trine::Store::File->temporary_store;

isa_ok($store, 'RDF::Trine::Store::File');

done_testing;
