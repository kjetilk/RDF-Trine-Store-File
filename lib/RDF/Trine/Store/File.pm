package RDF::Trine::Store::File;

use 5.006;
use strict;
use warnings;
use base qw(RDF::Trine::Store);
use RDF::Trine::Error qw(:try);
use RDF::Trine::Serializer::NTriples::Canonical;
use RDF::Trine::Parser;
use File::Data;
use File::Util;
use Scalar::Util qw(refaddr reftype blessed);
use File::Temp qw/tempfile/;
use Carp qw/croak/;
use Log::Log4perl;


=head1 NAME

RDF::Trine::Store::File - The great new RDF::Trine::Store::File!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use RDF::Trine::Store::File;

    my $foo = RDF::Trine::Store::File->new();
    ...

=head1 METHODS

=head2 new

=cut

sub new {
  my $class = shift;
  my $file  = shift;
  my($fu) = File::Util->new();
  unless (-r $file) {
    $fu->touch($file);
  }
  my $self  = bless(
		    {
		     file => $file,
		     fu   => $fu,
		     nser => RDF::Trine::Serializer::NTriples::Canonical->new,
		     log  => Log::Log4perl->get_logger("rdf.trine.store.file")
		    }, $class);
  return $self;
}


sub temporary_store {
  my $class = shift;
  my ($fh, $filename) = tempfile();
  return $class->new($filename);
}


=head2 add_statement

=cut

sub add_statement {
  my ($self, $st) = @_;
  unless (blessed($st) and $st->isa('RDF::Trine::Statement')) {
    throw RDF::Trine::Error::MethodInvocationError -text => "Not a valid statement object passed to add_statement";
  }
  my $mm = RDF::Trine::Model->temporary_model;
  $mm->add_statement($st);
  $self->{log}->debug("Attempting addition of statement");
  my $fd = File::Data->new($self->{file});
  $fd->append($self->{nser}->serialize_model_to_string($mm));
  return;
}

=head2 get_statements

=cut

sub get_statements {
  my $self = shift;
  my $regexp = $self->_search_regexp(@_);
  my $fd = File::Data->new($self->{file});
  $self->{log}->debug("Searching with regexp $regexp");
  my @lines = $fd->SEARCH($regexp);
  warn Dumper(\@lines);
  my $parser     = RDF::Trine::Parser->new( 'ntriples' );  
  my $mm = RDF::Trine::Model->temporary_model;
  $parser->parse_into_model( '', join('', @lines), $mm );
  return $mm->get_statements(undef, undef, undef, undef);
}

=head2 remove_statement

=cut

sub remove_statement {
  my ($self, $st) = @_;
  unless (blessed($st) and $st->isa('RDF::Trine::Statement')) {
    throw RDF::Trine::Error::MethodInvocationError -text => "Not a valid statement object passed to remove_statement";
  }
  my $mm = RDF::Trine::Model->temporary_model;
  $mm->add_statement($st);
  $self->{log}->debug("Attempting removal of statement");
  my $fd = File::Data->new($self->{file});
  $fd->REPLACE($self->{nser}->serialize_model_to_string($mm), '');
  return;
}


=head2 remove_statements

=cut

sub remove_statements {
  my $self = shift;
  my $regexp = $self->_search_regexp(@_);
  my $fd = File::Data->new($self->{file});
  $self->{log}->debug("Removing with regexp $regexp");
  my @lines = $fd->REPLACE($regexp, '');
  $self->{log}->info("Removed " . scalar @lines . " statements.");
  return;
}



=item C<< get_contexts >>

=cut

sub get_contexts {
  croak "Contexts not supported for the File store";
}

=item C<< size >>

Returns the number of statements in the store.

=cut

sub size {
  my $self = shift;
  return $self->{fu}->line_count($self->{file});
}

# Private method to create a regexp to be used in all kind of searching

sub _search_regexp {
  my $self = shift;
  my $i = 1;
  my @stmt;
  foreach my $term (@_) { # Create an array of RDF terms for later replacing for variables
    my $outterm = $term || RDF::Trine::Node::Resource->new("urn:rdf-trine-store-file-$i");
    push(@stmt, $outterm);
    $i++;
  }
  my $mm = RDF::Trine::Model->temporary_model;
  $mm->add_statement(RDF::Trine::Statement->new(@stmt));
  my $triple_resources = $self->{nser}->serialize_model_to_string($mm);
  chomp($triple_resources);
  $triple_resources =~ s/\.\s*$/\\./;
  $triple_resources =~ s/urn:rdf-trine-store-file-(1|2)/.*?/;
  $triple_resources =~ s/<urn:rdf-trine-store-file-3>/.*/;
  return '\'^(' . $triple_resources . '\r\n)\'';
}



=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-trine-store-file at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-Trine-Store-File>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RDF::Trine::Store::File


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RDF-Trine-Store-File>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RDF-Trine-Store-File>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RDF-Trine-Store-File>

=item * Search CPAN

L<http://search.cpan.org/dist/RDF-Trine-Store-File/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Kjetil Kjernsmo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of RDF::Trine::Store::File
