package SQL::OrderBy;

use strict;
# Use Exporter for a single function? Nah.
#use base 'Exporter';
#use vars qw(@EXPORT @EXPORT_OK);
#@EXPORT_OK = @EXPORT = qw(
#    toggle_resort
#);
use vars qw($VERSION);
$VERSION = '0.04';

# Transform the text of an order clause.
sub toggle_resort {
    my %args = @_;

    # Declare an ordered array and a direction hash of columns.
    my (@columns, %columns);

    # Get the columns and their order direction.
    # XXX This is an incredibly naive split.
    for (split /\s*,\s*/, $args{order_by}) {
        if (/^(.*?)(?:\s+(asc|desc))?$/i) {
            # By default, we ascend.
            $columns{$1} = $2 ? $2 : 'asc';
        }
        # Add the column to our columns array.
        push @columns, $1;
    }

    # Handle a newly selected column.
    if ($args{selected}) {
        # Toggle ascend/descend if the selected column is the first one.
        $columns{$args{selected}} =
            $args{selected} eq $columns[0]   &&
            exists $columns{$args{selected}} &&
            $columns{$args{selected}} eq 'asc'
            ? 'desc' : 'asc';
        # Remove the selected column name from its old position.
        @columns = grep { $_ ne $args{selected} } @columns;
        # Add the selected column name to the beginning.
        unshift @columns, $args{selected};
    }

    return join ', ', map { "$_ $columns{$_}" } @columns;
}

1;
__END__

=head1 NAME

SQL::OrderBy - Perl extension to transform an SQL ORDER BY clause.

=head1 SYNOPSIS

    use SQL::OrderBy;

    my $order = SQL::OrderBy::toggle_resort(
        order_by => 'name, artist, album',
        selected => 'artist',
    );
    # artist asc, name asc, album asc

    print SQL::OrderBy::toggle_resort(
        selected => 'time',
        order_by => SQL::OrderBy::toggle_resort(
            selected => 'artist',
            order_by => SQL::OrderBy::toggle_resort(
                selected => 'artist',
                order_by => 'name, artist, album'
            )
        )
    ), "\n";
    # time asc, artist desc, name asc, album asc

=head1 ABSTRACT

Resort and toggle (ascending/descending) table columns given an SQL
ORDER BY clause.

=head1 DESCRIPTION

This package simply transforms an SQL ORDER BY clause by moving or
adding column names and toggling their ascending/descending state.

Note that this is intentionally naive code, in that no database
integrity checking is done.

=head1 FUNCTIONS

=head2 toggle_resort()

    toggle_resort(
        order_by => $order_by_string,
        selected => $selected_column_name,
    )

The toggle_resort() function takes a (hopefully) well formed, SQL
"ORDER BY" clause as a simple string, and a column name provided as
named parameters.

The selected column name is moved or added to the beginning of the
clause with its sort direction exposed.  The clause is returned as a
string.

If this column is the first column of the list, it's sort direction
is flipped between ascending (asc) and descending (desc).

Note that the state of the sort is maintained, since the selected
column name is the only one that is fondled.

This implements an essential feature for GUI environments, where the
user interacts with a table by sorting and resorting with a mouse and
"toggle button column headings" during an interactive search
refinement session.

* If you leave off the selected argument, this function will simply
return the clause with sort directions for each column name.  That
is, no "toggling" or moving is done.

* Currently, this function is not exported by default.

=head1 DEPENDENCIES

None.

=head1 TODO

Add a toggle_resort() feature to accept an array reference instead of
a simple string only.

Add functions for different kinds of resorting, like "toggle reset".

Add functions for handling different module statement objects.

=head1 HISTORY

0.01 - Initial release.

0.02 - Documentation fixes and enhancement.

0.03 - Ack!  My synopsis!

0.04 - Renamed the resort() function.  Enhanced documentation.

=head1 AUTHOR

Gene Boggs, E<lt>cpan@ology.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
