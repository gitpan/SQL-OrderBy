package SQL::OrderBy;

use strict;
# Use Exporter for a single function? Nah.
#use base 'Exporter';
#use vars qw(@EXPORT @EXPORT_OK);
#@EXPORT_OK = @EXPORT = qw(
#    toggle_resort
#);
use vars qw($VERSION);
$VERSION = '0.05';

# Transform an order by clause.
sub toggle_resort {
    my %args = @_;

    # Declare an ordered array and a direction hash of columns.
    my ($columns, %columns);

    # Set the column list and the order directions.
    if (ref $args{order_by} eq 'ARRAY') {
        # The order clause was sent in as a list.
        $columns = $args{order_by};

        # Set the column direction hash.
        for (@$columns) {
            if (/^(.*?)(?:\s+(asc|desc))?$/i) {
                # Use the direction provided; Ascend by default.
                $columns{$1} = $2 ? $2 : 'asc';
            }
        }
    }
    else {
        # The order clause was sent in as a string.
        # Set the column direction hash.
        for (split /\s*,\s*/, $args{order_by}) {
            if (/^(.*?)(?:\s+(asc|desc))?$/i) {
                # Use the direction provided; Ascend by default.
                $columns{$1} = $2 ? $2 : 'asc';
            }

            # Add the column to our columns array.
            push @$columns, $1;
        }
    }

    # Handle a selected column.
    if (my $selected = $args{selected}) {
        # Toggle if the selected column is already the first one.
        $columns{$selected} =
            $selected eq $columns->[0] &&
            exists $columns{$selected} &&
            $columns{$selected} eq 'asc'
            ? 'desc' : 'asc';

        # Remove the selected column name from its old position.
        @$columns = grep { $_ ne $selected } @$columns;
        # And add the selected column name to the beginning.
        unshift @$columns, $selected;
    }

    # Return the column ordering as an arrayref or string.
    return wantarray
        ? map { "$_ $columns{$_}" } @$columns
        : join ', ', map { "$_ $columns{$_}" } @$columns;
#        return join ', ', map { "$_ $columns{$_}" } @$columns;
}

1;
__END__

=head1 NAME

SQL::OrderBy - Transform an SQL ORDER BY clause.

=head1 SYNOPSIS

    use SQL::OrderBy;

    # Array context
    my @order = SQL::OrderBy::toggle_resort(
        selected => 'artist',
        order_by => [ qw(name artist album) ],
    );
    # ('artist asc', 'name asc', 'album asc')

    # Scalar context
    print SQL::OrderBy::toggle_resort(
        selected => 'time',
        order_by => scalar SQL::OrderBy::toggle_resort(
            selected => 'artist',
            order_by => scalar SQL::OrderBy::toggle_resort(
                selected => 'artist',
                order_by => 'name, artist, album'
            )
        )
    );
    # 'time asc, artist desc, name asc, album asc'

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
        order_by => $order_clause_or_list,
        selected => $column_name,
    )

The toggle_resort() function takes two arguments provided as named
parameters: an SQL "ORDER BY" clause as either a string or array
reference and a column name.

The selected column name is moved or added to the beginning of the
clause with its sort direction exposed.  The clause is returned as a
string.

If this column is the first column of the list, it's sort direction
is flipped between ascending (asc) and descending (desc).

Note that the state of the sort is maintained, since the selected
column name is the only one that is fondled.

In a scalar context, this function returns the clause as a (CSV)
string.  In an array context, this function returns a list of column
names with their respective sort directions.

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

Add functions for different kinds of resorting, like "toggle reset".

Add functions for handling different module statement objects.

=head1 HISTORY

0.01  Mon Feb  3 14:11:20 2003
    - original version; created by h2xs 1.22 with options
        -X -n SQL::OrderBy

0.02  Mon Feb  3 2003
    - Fixed/enhanced documentation.
       
0.03  Mon Feb  3 2003
    - Ack!  My synopsis!
       
0.04  Fri Feb 21 2003
    - Renamed the resort() function.
    - Enhanced documentation.
       
0.05  Fri Feb 21 2003
    - Made toggle_resort() accept an arrayref or string.
    - Added scalar/array context awareness.
    - Fixed/enhanced documentation.

=head1 AUTHOR

Gene Boggs, E<lt>cpan@ology.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
