package SQL::OrderBy;

use strict;
use base 'Exporter';
use vars qw(@EXPORT @EXPORT_OK);
@EXPORT_OK = @EXPORT = qw(
    toggle_resort
    get_columns
    col_dir_list
    num2asc_desc
);
use vars qw($VERSION);
$VERSION = '0.07';

# sub toggle_resort {{{
# Transform an order by clause.
sub toggle_resort {
    my %args = @_;
    _set_defaults(\%args);

    # Declare an ordered array and a direction hash of columns.
    my ($columns, $direction);

    # Set the column name list and the directions.
    ($columns, $direction) = get_columns(
        order_by => $args{order_by},
        show_ascending => $args{show_ascending},
        name_direction => 1,
        numeric_direction => 1,
    );

    # Handle a selected column.
    if (my $selected = $args{selected}) {
        # Set the direction according to our show_ascending flag.
        $direction->{$selected} =
            !$direction->{$selected} || $direction->{$selected}
                ? 1 : 0;

        # Toggle if the selected column is the first one.
        if ($selected eq $columns->[0]) {
            $direction->{$selected} = $direction->{$selected}
                ? 0 : 1;
        }

        # Remove the selected column name from its old position.
        @$columns = grep { $_ ne $selected } @$columns;
        # And add the selected column name to the beginning.
        unshift @$columns, $selected;
    }

    %$direction = num2asc_desc ($direction, $args{show_ascending})
        unless $args{numeric_direction};
    
    @$columns = col_dir_list ($columns, $direction);

    # Return the column ordering as an arrayref or string.
    return wantarray ? @$columns : join ', ', @$columns;
}
# }}}

# sub get_columns {{{
# Return the column names and directions as either hash/array
# references, or a column array, or an "order by" clause.
sub get_columns {
    my %args = @_;
    _set_defaults(\%args);

    # Bail out unless we are given an order by clause or full SQL.
    die "No statement or clause provided.\n" unless $args{order_by};

    # Strip off any unneeded SQL clauses.
    $args{order_by} =~ s/^.*?\border by\s+(.*)$/$1/i;

    # Hold column names and directions.
    my ($columns, $direction);

    # The ordering was sent in as either a list or a clause.
    my @order = ref $args{order_by} eq 'ARRAY'
        ? @{ $args{order_by} }
        : split /\s*,\s*/, $args{order_by};

    # Set the column array and direction hash.
    for (@order) {
        if (/^(.*?)(?:\s+(asc|desc))?$/i) {
            # Use the direction provided; Ascend by default.
            $direction->{$1} = $2 && $2 eq 'desc' ? 0 : 1;
        }

        # Add the column to our columns array.
        push @$columns, $1;
    }

    %$direction = num2asc_desc ($direction, $args{show_ascending})
        unless $args{numeric_direction};

    # NOTE: name_direction only makes sense in an array context.
    if ($args{name_direction}) {
        $columns = [ $columns, $direction ];
    }
    else {
        @$columns = col_dir_list ($columns, $direction);
    }

    return wantarray ? @$columns : join ', ', @$columns;
}
# }}}

# sub col_dir_list {{{
# Return an array of column names with their respective directions concatinated.
sub col_dir_list {
    my ($columns, $direction) = @_;
    return map {
        $direction->{$_}
            ? "$_ $direction->{$_}"
            : $_
    } @$columns;
}
# }}}

# sub num2asc_desc {{{
# Return directions as "asc" and "desc" in place of their numeric eqivalents.
sub num2asc_desc {
    my ($dir, $show_ascending) = @_;
    return map {
        $_ => $dir->{$_}
            ? $show_ascending ? 'asc' : ''
            : 'desc'
    } keys %$dir;
}
# }}}

# sub _set_defaults {{{
# Naive little default argument setter.
sub _set_defaults {
    my $args = shift;
    $args->{show_ascending}    = 1 unless defined $args->{show_ascending};
    $args->{name_direction}    = 0 unless defined $args->{name_direction};
    $args->{numeric_direction} = 0 unless defined $args->{numeric_direction};
}
# }}}

1;
__END__

=head1 NAME

SQL::OrderBy - Transform an SQL ORDER BY clause.

=head1 SYNOPSIS

  use SQL::OrderBy;

  # Fetch the columns in array context.
  @columns = get_columns (
      order_by => 'name, artist desc, album',
  );
  # ('name asc', 'artist desc', 'album asc')

  # Fetch the columns in scalar context without the asc keyword.
  $columns = get_columns (
      order_by => ['name', 'artist desc', 'album'],
      show_ascending => 0,
  );
  # 'name, artist desc, album'

  # Fetch the columns as a name array and numeric direction hash.
  @columns = get_columns (
      order_by => 'name, artist desc, album',
      name_direction => 1,
      numeric_direction => 1,
  );
  # (['name','artist','album'], {name=>1, artist=>0, album=>1})

  @columns = col_dir_list (\@column_names, \%directions);

  %directions = num2asc_desc (\%directions, 0);

  # Toggle resort in array context.
  @order = toggle_resort (
      selected => 'artist',
      order_by => ['name', 'artist', 'album'],
  );
  # ('artist asc', 'name asc', 'album asc')

  # Toggle resort in scalar context without the asc keyword.
  print scalar toggle_resort (
      show_ascending => 0,
      selected => 'time',
      order_by => scalar toggle_resort(
          selected => 'artist',
          order_by => scalar toggle_resort(
              selected => 'artist',
              order_by => 'name asc, artist asc, album asc'
          )
      )
  );
  # 'time, artist desc, name, album'

=head1 ABSTRACT

Resort and toggle (ascending/descending) table columns given an SQL
ORDER BY clause.

=head1 DESCRIPTION

This package simply transforms an SQL ORDER BY clause by moving or
adding column names and toggling their ascending/descending state.

Note that this is intentionally naive code, in that no database
integrity checking is done.

=head1 FUNCTIONS

=head2 toggle_resort ()

  toggle_resort(
      order_by => $order_clause_or_list,
      selected => $column_name,
  )

This function takes two arguments provided as named parameters: an 
SQL "ORDER BY" clause as either a string or array reference and a 
column name.

The selected column name is moved or added to the beginning of the
clause with its sort direction exposed.  If this column is the first
column of the list, its sort direction is flipped between ascending
(asc) and descending (desc).

Note that the state of the sort is maintained, since the selected
column name is the only one that is fondled.

In a scalar context, this function returns the clause as a (CSV)
string.  In an array context, this function returns a list of column
names with their respective sort directions.

This function optionally takes Boolean flags affecting the returned
data structure.  These are:
 
show_ascending => Expose the asc column directions.  Defaults on (1).

name_direction => Return references to the column names and their
directions.  Defaults off (0).  Only makes sense in array context.

numeric_direction => Return Boolean column directions, instead of
asc/desc.  Defaults off (0).  Only makes sense with the
name_direction flag on.

This implements an essential feature for GUI environments, where the
user interacts with a table by sorting and resorting with a mouse and
"toggle button column headings" during an interactive search
refinement session.

* If you leave off the selected argument, this function will simply
return the clause with sort directions for each column name.  That
is, no "toggling" or moving is done.

* Currently, this function is not exported by default.

=head2 get_columns ()

  @columns = get_columns (
      order_by => $order_clause_or_list,
      show_ascending    => $x,
      name_direction    => $y,
      numeric_direction => $z,
  )

  $columns = get_columns (
      order_by => $order_clause_or_list,
      show_ascending => $x,
  )

This function simply returns a well formed order by clause or list.
It can accept either a string or array reference for the order_by
argument.

In a scalar context, this function returns the clause as a (CSV)
string.  In an array context, this function returns a list of column
names with their respective sort directions.

This function optionally takes Boolean flags affecting the returned
data structure.  These are:
 
show_ascending => Expose the asc column directions.  Defaults on (1).

name_direction => Return references to the column names and their
directions.  Defaults off (0).  Only makes sense in array context.

numeric_direction => Return Boolean column directions, instead of
asc/desc.  Defaults off (0).  Only makes sense with the
name_direction flag on.

=head2 col_dir_list ()

  @columns = col_dir_list (\@columns, \%asc_desc);

Return an array of column names with their respective directions
concatinated.

This function takes a reference to an array of column names and a
reference to a direction hash.

=head2 num2asc_desc ()

  %directions = num2asc_desc (\%directions, $show_asc)

Return directions as "asc" and "desc" in place of their numeric
eqivalents.

This function takes a reference to a direction hash and an optional
flag to control the display of the asc keyword.

=head1 DEPENDENCIES

None.

=head1 TODO

Add functions for different kinds of resorting?

Add the ability to return the order by clause without altering the
case (or display) of column names and directions.

=head1 HISTORY

See the Changes file in this distribution.

=head1 AUTHOR

Gene Boggs, E<lt>cpan@ology.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
