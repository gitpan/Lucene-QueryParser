package Lucene::QueryParser;

use 5.00503;
use strict;
use Carp;

require Exporter;
use Text::Balanced qw(extract_bracketed extract_delimited);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw( parse_query deparse_query );
@EXPORT = qw( parse_query deparse_query );
$VERSION = '1.02';

sub parse_query {
    local $_ = shift;
    my @rv;
    while ($_) {
        s/^\s+// and next;
        my $item;
        s/^(AND|OR|\|\|)\s+//;
        if ($1)                   { $item->{conj} = $1; }
        if (s/^\+//)              { $item->{type} = "REQUIRED";   }
        elsif (s/^(-|!|NOT)\s*//i){ $item->{type} = "PROHIBITED"; }
        else                      { $item->{type} = "NORMAL";     }

        if (s/^([^\s(":]+)://)      { $item->{field} = $1 }

        # Subquery
        if (/^\(/) {
            my ($extracted, $remainer) = extract_bracketed($_,"(");
            if (!$extracted) { croak "Unbalanced subquery" }
            $_ = $remainer;
            $extracted =~ s/^\(//;
            $extracted =~ s/\)$//;
            $item->{query} = "SUBQUERY";
            $item->{subquery} = parse_query($extracted);
        } elsif (/^"/) {
            my ($extracted, $remainer) = extract_delimited($_, '"');
            if (!$extracted) { croak "Unbalanced phrase" }
            $_ = $remainer;
            $extracted =~ s/^"//;
            $extracted =~ s/"$//;
            $item->{query} = "PHRASE";
            $item->{term} = $extracted;
        } elsif (s/^(\S+)\*//) {
            $item->{query} = "PREFIX";
            $item->{term} = $1;
        } else {
            s/([^\s\^]+)// or croak "Malformed query";
            $item->{query} = "TERM";
            $item->{term} = $1;
        }

        if (s/^\^(\d+(?:.\d+))//)  { $item->{boost} = $1 }

        push @rv, $item;
    }
    return \@rv;
}

sub deparse_query {
    my $ds = shift;
    my @out; 
    for my $elem (@$ds) {
        my $thing = "";
        if ($elem->{conj}) { $thing .= "$elem->{conj} "; }
        if ($elem->{type} eq "REQUIRED") {
            $thing .= "+";
        } elsif ($elem->{type} eq "PROHIBITED") {
            $thing .= "-";
        }
        if (exists $elem->{field}) { 
            $thing .= $elem->{field}.":"
        }
        if ($elem->{query} eq "TERM") {
            $thing .= $elem->{term};
        } elsif ($elem->{query} eq "SUBQUERY") {
            $thing .= "(".deparse_query($elem->{subquery}).")";
        } elsif ($elem->{query} eq "PHRASE") {
            $thing .= '"'.$elem->{term}.'"';
        }
        if (exists $elem->{boost}) { $thing .= "^".$elem->{boost} }
        push @out, $thing;
    }
    return join " ", @out;
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lucene::QueryParser - Turn a Lucene query into a Perl data structure

=head1 SYNOPSIS

  use Lucene::QueryParser;
  my $structure = parse_query("red and yellow and -(coat:pink and green)");

C<$structure> will be:

 [ { query => 'TERM', type => 'NORMAL', term => 'red' },
   { query => 'TERM', type => 'NORMAL', term => 'yellow' },
   { subquery => [
        { query => 'TERM', type => 'NORMAL', term => 'pink', field => 'coat' },
        { query => 'TERM', type => 'NORMAL', term => 'green' }
     ], query => 'SUBQUERY', type => 'PROHIBITED' 
   }
 ]

=head1 DESCRIPTION

This module parses a Lucene query, as defined by 
http://lucene.sourceforge.net/cgi-bin/faq/faqmanager.cgi?file=chapter.search&toc=faq#q5

It deals with fields, types, phrases, subqueries, and so on; everything
handled by the C<SimpleQuery> class in Lucene. The data structure is similar
to the one given above, and is pretty self-explanatory.

The other function, C<deparse_query> turns such a data structure back into
a Lucene query string. This is useful if you've just been mucking about
with the data.

=head2 EXPORT

Exports the C<parse_query> and C<deparse_query> functions.

=head1 AUTHOR

Simon Cozens, E<lt>simon@kasei.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Kasei

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
