package SQL::OrderBy;

use strict;
use base 'Exporter';
use vars qw(@EXPORT @EXPORT_OK);
@EXPORT_OK = @EXPORT = qw(
    toggle_resort
    get_columns
    col_dir_list
    to_asc_desc
);
use vars qw($VERSION);
$VERSION = '0.08.1';

# sub toggle_resort {{{
# Transform an order by clause.
sub toggle_resort {
    my %args = @_;

    # Set the column name list and the directions.
    my ($columns, $direction) = get_columns(
        %args,
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

    # Convert from numeric, if asked to.
    %$direction = to_asc_desc ($direction, %args)
        unless $args{numeric_direction};

    # Fetch our "name direction" array.
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

    # Set the order array from the order_by argument.
    my @order;
    if (ref $args{order_by} eq 'ARRAY') {
        @order = @{ $args{order_by} };
#        warn "Empty order list provided." unless @order;
    }
    else {
        if ($args{order_by}) {
            # Strip off any unneeded SQL clauses.
            $args{order_by} =~ s/^.*?\border by\s+(.*)$/$1/i;
            # Split the order clause.
            @order = split /\s*,\s*/, $args{order_by};
        }
        else {
            @order = ();
#            warn "No statement or clause provided.\n" unless $args{order_by};
        }
    }

    # Hold column names and directions.
    my ($columns, $direction);

    # Set the column array and direction hashes.
    my $asc_desc = {};
    for (@order) {
        if (/^(.*?)(?:\s+(asc|desc))?$/i) {
            # Use the direction provided; Ascend by default.
            my ($name, $dir) = ($1, $2);
            # Set the numeric directions.
            $direction->{$name} = $dir && lc ($dir) eq 'desc' ? 0 : 1;
            # Set the case sensitive alpha directions.
            $asc_desc->{$name} = $dir ? $dir : '';
        }

        # Add the column to our columns array.
        push @$columns, $1;
    }

    # Make alpha directions if asked to.
    %$direction = to_asc_desc ($asc_desc, %args)
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
# This is conditional concatination.  ASC/DESC vs. 1/0 issues do not concern us here.
sub col_dir_list {
    my ($columns, $direction) = @_;
    return map {
        $direction->{$_}
            ? "$_ $direction->{$_}"
            : $_
    } @$columns;
}
# }}}

# sub to_asc_desc {{{
# Return alpha directions in place of numeric eqivalents.
sub to_asc_desc {
    my $dir = shift;
    my %args = @_;

    # Set default direction strings.
    my ($asc, $desc) = $args{uc_direction}
        ? ('ASC', 'DESC') : ('asc', 'desc');

    # Replace directions with "proper" values.
    for (keys %$dir) {
        # From numeric
        if (defined $dir->{$_} && $dir->{$_} =~ /^\d+$/) {
            $dir->{$_} = $dir->{$_}
                ? $args{show_ascending} ? $asc : ''
                : $desc;
        }
        # Use existing if present, ascend otherwise.
        else {
            $dir->{$_} = $dir->{$_}
                ? lc ($dir->{$_}) eq 'desc'
                    ? $dir->{$_}
                    : $args{show_ascending} ? $dir->{$_} : ''
                : $args{show_ascending} ? $asc : ''
        }
    }

    return %$dir;
}
# }}}

1;
__END__

=head1 NAME

SQL::OrderBy - Transform an SQL "order by" clause.

=head1 SYNOPSIS

  use SQL::OrderBy;

  # Fetch the columns in array context.
  @columns = get_columns (
      order_by => 'Name, Artist Desc, Album',
  );
  # ('Name', 'Artist Desc', 'Album')

  # Fetch the columns in scalar context.
  $columns = get_columns (
      order_by => ['NAME', 'ARTIST DESC', 'ALBUM'],
      show_ascending => 1,
      uc_direction => 1,
  );
  # 'NAME ASC, ARTIST DESC, ALBUM ASC'

  # Fetch the columns as a name array and numeric direction hash.
  @columns = get_columns (
      order_by => 'name, artist desc, album',
      name_direction    => 1,
      numeric_direction => 1,
  );
  # (['name','artist','album'], {name=>1, artist=>0, album=>1})

  # Output a "column direction" array.
  @columns = col_dir_list (\@column_names, \%direction);
  # ('name', 'artist desc', 'album')

  # Convert numeric directions to SQL keywords.
  %direction = to_asc_desc (
      \%direction,
      show_ascending => 1,
  );
  # (name=>'asc', artist=>'desc', album=>'asc')

  # Single toggle resort in array context.
  @order = toggle_resort (
      show_ascending => 1,
      selected => 'artist',
      order_by => ['name', 'artist', 'album'],
  );
  # ('artist asc', 'name asc', 'album asc')

  # Nested toggle resort in scalar context.
  print scalar toggle_resort (
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

=head2 toggle_resort

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

show_ascending => Expose the asc column directions.  Off by default.

name_direction => Return references to the column names and their
directions.  Off by default.  Only makes sense in array context.

numeric_direction => Return Boolean column directions, instead of
asc/desc.  Off by default.  Only makes sense with the name_direction
flag on.

uc_direction => Render any new alpha column direction in uppercase.
Off by default.

This implements an essential feature for GUI environments, where the
user interacts with a table by sorting and resorting with a mouse and
"toggle button column headings" during an interactive search
refinement session.

* If you do not include the selected argument, this function will
simply return the clause with sort directions for each column name.
That is, no "toggling" or moving is done.

=head2 get_columns

  @columns = get_columns (
      order_by => $order_clause_or_list,
      uc_direction      => $w,
      show_ascending    => $x,
      name_direction    => $y,
      numeric_direction => $z,
  )

  $columns = get_columns (
      order_by => $order_clause_or_list,
      show_ascending => $x,
      uc_direction   => $y,
  )

This function simply returns a well formed order by clause or list.
It can accept either a string or array reference for the order_by
argument.

In a scalar context, this function returns the clause as a (CSV)
string.  In an array context, this function returns a list of column
names with their respective sort directions.

This function optionally takes Boolean flags affecting the returned
data structure.  These are:

show_ascending => Expose the asc column directions.  Off by default.

name_direction => Return references to the column names and their
directions.  Off by default.  Only makes sense in array context.

numeric_direction => Return Boolean column directions, instead of
asc/desc.  Off by default.  Only makes sense with the
name_direction flag on.

uc_direction => Render new alpha column directions in uppercase.
Off by default.

=head2 col_dir_list

  @columns = col_dir_list (\@columns, \%direction);

Return an array of column names with their respective directions
concatinated.

This function takes a reference to an array of column names and a
reference to a direction hash.

=head2 to_asc_desc

  %asc_desc = to_asc_desc (
      \%direction,
      show_ascending => $x,
      uc_direction   => $y,
  )

Return column directions as alpha keywords in place of their numeric
eqivalents.  Note that, if the direction hash contains any alpha
(asc/desc) values, the function uses those by default.

This function takes a reference to a direction hash and optional
flags to control the display of the asc keyword and new direction
names.  These flags are:

show_ascending => Expose asc column directions.  Off by default.

uc_direction => Render new alpha column directions in uppercase.  Off
by default.

=head1 DEPENDENCIES

None.

=head1 TODO

Add functions for different kinds of resorting?

=head1 HISTORY

See the Changes file in this distribution.

=head1 AUTHOR

Gene Boggs, E<lt>cpan@ology.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
