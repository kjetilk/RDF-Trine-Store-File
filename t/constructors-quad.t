#!/usr/bin/perl

use Test::More;
use Test::RDF;
use File::Util;
use RDF::Trine;
use File::Temp qw/tempfile cleanup/;

use_ok('RDF::Trine::Store::File::Quad');

my $stmt = RDF::Trine::Statement::Quad->new(
				      RDF::Trine::Node::Resource->new('http://example.org/a'),
				      RDF::Trine::Node::Resource->new('http://example.org/b'),
				      RDF::Trine::Node::Resource->new('http://example.org/c'),
				      RDF::Trine::Node::Resource->new('http://example.org/d')
				     );

{
  note "Testing temporary_store";
  my $store = RDF::Trine::Store::File::Quad->temporary_store;
  isa_ok($store, 'RDF::Trine::Store::File::Quad');
  $store->add_statement($stmt);
  is($store->size, 1, 'Store has one statement according to size');
  my $iter = $store->get_statements(undef, undef, undef, undef);
  my $st = $iter->next;
  ok($stmt->subsumes($st), "The same statement was returned");
  $store->nuke;
}

{
  note "Testing new_with_string";
  my ($fh, $filename) = tempfile(EXLOCK => 0);
  my $store = RDF::Trine::Store::File::Quad->new_with_string('File::Quad;'.$filename);
  isa_ok($store, 'RDF::Trine::Store::File::Quad');
  $store->add_statement($stmt);
  is($store->size, 1, 'Store has one statement according to size');
  my $iter = $store->get_statements(undef, undef, undef, undef);
  my $st = $iter->next;
  ok($stmt->subsumes($st), "The same statement was returned");
  $store->nuke;
}

{
  note "Testing new_with_config";
  my ($fh, $filename) = tempfile(EXLOCK => 0);
  my $store = RDF::Trine::Store::File::Quad->new_with_config({ storetype => 'File::Quad', file => $filename});
  isa_ok($store, 'RDF::Trine::Store::File::Quad');
  $store->add_statement($stmt);
  is($store->size, 1, 'Store has one statement according to size');
  my $iter = $store->get_statements(undef, undef, undef, undef);
  my $st = $iter->next;
  ok($stmt->subsumes($st), "The same statement was returned");
  $store->nuke;
}

{
  note "Testing new_with_config from Store";
  my ($fh, $filename) = tempfile(EXLOCK => 0);
  my $store = RDF::Trine::Store->new_with_config({ storetype => 'File::Quad', file => $filename});
  isa_ok($store, 'RDF::Trine::Store::File::Quad');
  $store->add_statement($stmt);
  is($store->size, 1, 'Store has one statement according to size');
  my $iter = $store->get_statements(undef, undef, undef, undef);
  my $st = $iter->next;
  ok($stmt->subsumes($st), "The same statement was returned");
  $store->nuke;
}


done_testing;
