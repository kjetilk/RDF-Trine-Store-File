use Test::More;

if ($ENV{RELEASE_TESTING} || $ENV{AUTOMATED_TESTING}) {
	plan skip_all => 'It is known to crash, but it is OK for dev release.'
}

use Test::RDF::Trine::Store;

use RDF::Trine qw(iri variable store literal);

use RDF::Trine::Store::File;

my $data = Test::RDF::Trine::Store::create_data;

my $store	= RDF::Trine::Store::File->temporary_store();
isa_ok( $store, 'RDF::Trine::Store::File' );

Test::RDF::Trine::Store::all_store_tests($store, $data, 0,
													  {suppress_dupe_tests => 1,
														update_sleep => 1
													  });

$store->nuke;
done_testing;
