#!/usr/bin/perl

use Test::More;

use_ok('RDF::Trine::Store::File');

my $store = RDF::Trine::Store::File->temporary_store;

isa_ok($store, 'RDF::Trine::Store::File');

TODO: {
  local $TODO = "Create regex";
{
  my $regex = $store->_search_regexp(undef,
				     RDF::Trine::Node::Resource->new('http://example.org/b'),
				     RDF::Trine::Node::Resource->new('http://example.org/c')
				    );
  is($regex, '^<(.*?)> <http://example.org/b> <http://example.org/c> \.\r\n', 'Subject variable matches');
}

{
  my $regex = $store->_search_regexp(RDF::Trine::Node::Resource->new('http://example.org/a'),
				     RDF::Trine::Node::Resource->new('http://example.org/d'),
				     undef
				    );
  is($regex, '^<http://example.org/a> <http://example.org/d> (.*) \.\r\n', 'object variable matches');
}

{
  my $regex = $store->_search_regexp(RDF::Trine::Node::Resource->new('http://example.org/a'),
				     undef,
				     undef
				    );
  is($regex, '^<http://example.org/a> <(.*?)> (.*) \.\r\n', 'predicate and object variable matches');
}

}

done_testing;
