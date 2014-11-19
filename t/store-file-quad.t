use Test::More;

use Test::RDF::Trine::Store;

use RDF::Trine qw(iri variable store literal);

use RDF::Trine::Store::File::Quad;

my $data = Test::RDF::Trine::Store::create_data;

my $store	= RDF::Trine::Store::File::Quad->temporary_store();
isa_ok( $store, 'RDF::Trine::Store::File::Quad' );

Test::RDF::Trine::Store::all_store_tests($store, $data, 1, 
													  {suppress_dupe_tests => 1,
														update_sleep => 1
													  });

done_testing;
