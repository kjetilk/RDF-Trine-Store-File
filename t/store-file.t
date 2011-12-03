use Test::More skip_all => 'Test::RDF::Trine::Store isnt ready for triples only';

use Test::RDF::Trine::Store qw(all_store_tests number_of_tests);

use RDF::Trine qw(iri variable store literal);

use RDF::Trine::Store::File;

my $data = Test::RDF::Trine::Store::create_data;
my $store	= RDF::Trine::Store::File->temporary_store();
isa_ok( $store, 'RDF::Trine::Store::File' );

Test::RDF::Trine::Store::all_triple_store_tests($store, $data);

done_testing;
