package SQL::OrderBy;

use strict;

use base 'Exporter';
use vars qw($VERSION @EXPORT @EXPORT_OK);

@EXPORT_OK = @EXPORT = qw(
    resort
);

$VERSION = '0.03';

sub resort {
    my %args = @_;

    # We need a couple buckets for this job.
    my (@columns, %columns);

    # Get the columns and their order direction.
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

    my $string = join ', ', map { "$_ $columns{$_}" } @columns;
#    warn $string, "\n";
    return $string;
}

1;
__END__

=head1 NAME

SQL::OrderBy - Perl extension to transform an SQL ORDER BY clause.

=head1 SYNOPSIS

    use SQL::OrderBy;

    my $order = resort(
        order_by => 'name, artist, album',
        selected => 'artist',
    );
    # artist asc, name asc, album asc

    print resort(
        order_by => resort(
            order_by => resort(
                order_by => 'name, artist, album',
                selected => 'artist',
            ),
            selected => 'artist',
        ),
        selected => 'time',
    ), "\n";
    # time asc, artist desc, name asc, album asc

=head1 ABSTRACT

Resort and toggle (ascending/descending) table columns given an SQL
ORDER BY clause and a selected column name.

=head1 DESCRIPTION

This package simply transforms an SQL ORDER BY clause by moving a
selected column name to the beginning of the clause and toggling
its ascending/descending state based on whether it is already first
in the clause.

This implements a feature that is essential for GUI environments,
where the user interacts with a table by sorting and resorting with a
mouse and "toggle button column headings" during an SQL driven,
interactive search refinement session.

Note that this is intentionally naive code, in that no database
integrity checking is done.

=head1 EXPORTS

=head2 resort()

    resort(
        order_by => $order_by_string,
        selected => $selected_column_name,
    )

The resort() function takes a (hopefully) well formed, SQL "ORDER
BY" clause as a simple string, and a column name as arguments.
These must be provided as named parameters.

The column name is moved or added to the beginning of the clause
with its sort direction exposed.

If this column is the first column of the list, its sort direction
is flipped between ascending (asc) and descending (desc).

Note that the state of the sort is maintained, since the selected
column name is the only one that is fondled.

* If you leave off the selected argument, this function will simply
return the clause with sort directions for each column name.  That
is, no "toggling" or moving is done.

=head1 DEPENDENCIES

None.

=head1 HISTORY

0.01 - Initial release.
0.02 - Documentation fixes and enhancement.
0.03 - Ack!  My synopsis!

=head1 AUTHOR

Gene Boggs, E<lt>cpan@ology.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
