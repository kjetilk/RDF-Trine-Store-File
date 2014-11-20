package RDF::Trine::Store::File::Quad;

use 5.006;
use strict;
use warnings;
use base qw(RDF::Trine::Store::File);
use RDF::Trine::Error qw(:try);
use RDF::Trine::Serializer::NQuads;
use RDF::Trine::Parser;
use File::Data;
use File::Util;
use Scalar::Util qw(blessed);
use File::Temp qw/tempfile/;
use Carp qw/croak/;
use Log::Log4perl;
use Digest::MD5 ('md5_hex');
use List::MoreUtils qw(uniq);


=head1 NAME

RDF::Trine::Store::File::Quad - Using a file with N-Quads as quadstore

=head1 SYNOPSIS

To be used as a normal quad store.

  my $store = RDF::Trine::Store::File->new($filename);
  $store->add_statement(RDF::Trine::Statement->new(
						   RDF::Trine::Node::Resource->new('http://example.org/a'),
						   RDF::Trine::Node::Resource->new('http://example.org/b'),
						   RDF::Trine::Node::Resource->new('http://example.org/c')
						   RDF::Trine::Node::Resource->new('http://example.org/d')
						  ));
  ...

=head1 METHODS

=head2 new($filename)

A constructor, takes a filename as parameter. If the file doesn't
exist, it will be created.

=cut

sub new {
  my $class = shift;
  my $file  = shift;
  my($fu) = File::Util->new();
  unless (-e $file) {
    $fu->touch($file);
  }
  my $self  = bless(
		    {
		     file => $file,
		     fu	  => $fu,
			  parser => 'nquads',
		     nser => RDF::Trine::Serializer::NQuads->new,
		     log  => Log::Log4perl->get_logger("rdf.trine.store.file.quad")
		    }, $class);
  return $self;
}

=head2 new_with_string('File::Quad;'.$filename)

A constructor, takes a string config as parameter. If the file doesn't
exist, it will be created. The string will typically begin with C<File::Quad;>, e.g.

  my $store = RDF::Trine::Store::File::Quad->new_with_string('File::Quad;/path/to/file.nt');

=head2 new_with_config({ storetype => 'File::Quad', file => $filename});

A constructor, takes a hashref config as parameter. If the file doesn't
exist, it will be created. It needs to have a C<storetype> key with C<File::Quad> as the value, e.g.

  my $store = RDF::Trine::Store::File::Quad->new_with_config({ storetype => 'File::Quad', file => $filename});

=head2 temporary_store

Constructor that creates a temporary file to work on.

=head2 add_statement($statement)

Adds the specified C<$statement> to the underlying model.

=cut

sub add_statement {
  my $self = shift;
  my $st = _check_arguments(@_);
  my $mm = RDF::Trine::Model->temporary_model;
  $mm->add_statement($st);
  $self->{log}->debug("Attempting addition of statement");
  $self->{log}->trace("with terms " . $st->as_string);
  my $fd = File::Data->new($self->{file});
  $fd->append($self->{nser}->serialize_model_to_string($mm));
  return;
}

=head2 get_statements($subject, $predicate, $object, $context)

Returns a iterator object of all statements matching the specified subject,
predicate, object and graph. Any of the arguments may be undef to match any value.

=head2 count_statements($subject, $predicate, $object)

Returns a count of all the statements matching the specified subject,
predicate and objects. Any of the arguments may be undef to match any value.

=head2 remove_statement($statement)

Removes the specified C<$statement> from the underlying model.

=cut

sub remove_statement {
  my $self = shift;
  my $st = _check_arguments(@_);
  unless (blessed($st) and $st->isa('RDF::Trine::Statement')) {
    throw RDF::Trine::Error::MethodInvocationError -text => "Not a valid statement object passed to remove_statement";
  }
  my $mm = RDF::Trine::Model->temporary_model;
  $mm->add_statement($st);
  $self->{log}->debug("Attempting removal of statement");
  my $fd = File::Data->new($self->{file});
  my $triple = $self->{nser}->serialize_model_to_string($mm);
  $triple =~ s/\^/\\^/g;
  $triple =~ s/\\u/\\\\u/g;
  $fd->REPLACE($triple, '');
  return;
}


=head2 remove_statements($subject, $predicate, $object, $context)

Removes all statement matching the specified subject, predicate,
objects and graph. Any of the arguments may be undef to match any value.

=head2 get_contexts

Will return an iterator with contexts (aka graph names).

=cut


sub get_contexts {
  my $self = shift;
  my $fd = File::Data->new($self->{file});
  my @contexts = $fd->SEARCH('^(?:<.*?>|_\:\\w+?) <.+?> .+? <.+?> \.\n$');
  croak 'Could not find any quads in ' . $self->{file} if (scalar @contexts == 0);
  return RDF::Trine::Iterator->new([uniq(@contexts)]);
}


=head2 size

Returns the number of statements in the store. Breaks if there are
comments or empty lines in the file.

=head2 etag

Returns an etag based on the last modification time of the file. Note:
This has resolution of one second, so it cannot be relied on for data
that changes fast.

=head2 nuke

Permanently removes the store file and its data.

=cut

# Private method to create a regexp to be used in all kind of searching

sub _search_regexp {
  my $self = shift;
  my @terms = @_;

  my $i = 1;
  my @stmt;
  foreach my $term (@terms[0..3]) { # Create an array of RDF terms for later replacing for variables
    my $outterm = $term || RDF::Trine::Node::Resource->new("urn:rdf-trine-store-file-$i");
    $outterm = RDF::Trine::Node::Resource->new("urn:rdf-trine-store-file-$i") if ($outterm->isa('RDF::Trine::Node::Variable'));
    push(@stmt, $outterm);
    $i++;
  }
  my $mm = RDF::Trine::Model->temporary_model;
  $mm->add_statement(RDF::Trine::Statement::Quad->new(@stmt));
  my $triple_resources = $self->{nser}->serialize_model_to_string($mm);
  chomp($triple_resources);
  $triple_resources =~ s/\.\s*$/\\./;
  $triple_resources =~ s/<urn:rdf-trine-store-file-1>/(?:<.*?>|_\:\\w+?)/;
  $triple_resources =~ s/urn:rdf-trine-store-file-2/.*?/;
  $triple_resources =~ s/<urn:rdf-trine-store-file-3>/.+/;
  $triple_resources =~ s/<urn:rdf-trine-store-file-4>/(?:(?:<.*?>|_\:\\w+?))?/;
  $triple_resources =~ s/ \\.$/ \?\\./g;
  $triple_resources =~ s/\^/\\^/g;
  $triple_resources =~ s/\\u/\\\\u/g;
  my $out = '(' . $triple_resources . '\n)';
  $self->{log}->debug("Search regexp: $out");
  return $out;
}

# Ensures that we get a quad back

sub _check_arguments {
	my $st = shift;
	my $context = shift;
	if (blessed($st) && $st->isa( 'RDF::Trine::Statement::Quad' )) {
		if (blessed($context)) {
			throw RDF::Trine::Error::MethodInvocationError -text => "add_statement cannot be called with both a quad and a context";
		}
	} else {
		my @nodes	= $st->nodes;
		if (blessed($context)) {
			$st	= RDF::Trine::Statement::Quad->new( @nodes[0..2], $context );
		} else {
#			my $nil	= RDF::Trine::Node::Resource->new('urn:rdf-trine-store-file-nil');
			my $nil	= RDF::Trine::Node::Nil->new;
			$st	= RDF::Trine::Statement::Quad->new( @nodes[0..2], $nil );
		}
	}
	return $st;
}


=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012,2014 Kjetil Kjernsmo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of RDF::Trine::Store::File
