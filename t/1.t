use strict;
use Test::More tests => 17;

BEGIN { use_ok('SQL::OrderBy') };

# fetch a numeric name_direction list
my @columns = SQL::OrderBy::get_columns(
    order_by => 'name, artist desc, album',
    show_ascending => 1,
    name_direction => 1,
    numeric_direction => 1,
);
is join (', ', @{ $columns[0] }),
    'name, artist, album',
    'column name list for name_direction';
is join (', ', map { "$_ $columns[1]->{$_}" } sort keys %{ $columns[1] }),
    'album 1, artist 0, name 1',
    'column directions for numeric name_direction';

# fetch a asc/desc name_direction list
@columns = SQL::OrderBy::get_columns(
    order_by => 'name, artist desc, album',
    show_ascending => 1,
    name_direction => 1,
    numeric_direction => 0,
);
is join (', ', map { "$_ $columns[1]->{$_}" } sort keys %{ $columns[1] }),
    'album asc, artist desc, name asc',
    'column directions for asc/desc name_direction';

# convert column directions
my %direction = (name => 1, artist => 0, album => 1);
%direction = num2asc_desc (\%direction, 0);
is join (', ', map { $direction{$_} ? "$_ $direction{$_}" : $_ } sort keys %direction),
    'album, artist desc, name',
    'numeric column directions to hidden asc/desc';
%direction = (name => 1, artist => 0, album => 1);
%direction = num2asc_desc (\%direction, 1);
is join (', ', map { $direction{$_} ? "$_ $direction{$_}" : $_ } sort keys %direction),
    'album asc, artist desc, name asc',
    'numeric column directions to exposed asc/desc';

# render a column name direction list
%direction = (name => 'asc', artist => 'desc', album => 'asc');
@columns = col_dir_list ([qw(name artist album)], \%direction);
is join (', ', @columns), 'name asc, artist desc, album asc',
    'column name direction list rendered';

# fetch column names with exposed direction
# in array context
@columns = SQL::OrderBy::get_columns(
    order_by => 'name, artist desc, album',
    show_ascending => 1,
    name_direction => 0,
);
is join (', ', @columns), 'name asc, artist desc, album asc',
    'column names with exposed direction in array context';
# in scalar context
my $columns = SQL::OrderBy::get_columns(
    order_by => ['name', 'artist desc', 'album'],
    show_ascending => 1,
    name_direction => 0,
);
is $columns, 'name asc, artist desc, album asc',
    'column names with exposed direction in scalar context';

# fetch column names with hidden asc
# in array context
@columns = SQL::OrderBy::get_columns(
    order_by => 'name asc, artist desc, album',
    show_ascending => 0,
    name_direction => 0,
);
is join (', ', @columns), 'name, artist desc, album',
    'column names with hidden asc in array context';
# in scalar context
$columns = SQL::OrderBy::get_columns(
    order_by => ['name', 'artist desc', 'album'],
    show_ascending => 0,
    name_direction => 0,
);
is $columns, 'name, artist desc, album',
    'column names with hidden asc in scalar context';

# toggle in scalar context
my $order = SQL::OrderBy::toggle_resort(
    selected => 'artist',
    order_by => 'name, artist, album',
);
is $order, 'artist asc, name asc, album asc',
    'order clause in scalar context';
$order = SQL::OrderBy::toggle_resort(
    selected => 'artist',
    order_by => [ qw(name artist album) ],
);
is $order, 'artist asc, name asc, album asc',
    'order array in scalar context';

# toggle in array context
my @order = SQL::OrderBy::toggle_resort(
    selected => 'artist',
    order_by => 'name, artist, album',
);
is join (', ', @order), 'artist asc, name asc, album asc',
    'order clause in array context';
@order = SQL::OrderBy::toggle_resort(
    selected => 'artist',
    order_by => [ qw(name artist album) ],
);
is join (', ', @order), 'artist asc, name asc, album asc',
    'order array in array context';

# hidden asc nested toggle
$order = SQL::OrderBy::toggle_resort(
    show_ascending => 0,
    selected => 'time',
    order_by => scalar SQL::OrderBy::toggle_resort(
        selected => 'artist',
        order_by => scalar SQL::OrderBy::toggle_resort(
            selected => 'artist',
            order_by => 'name asc, artist asc, album asc',
        )
    )
);
is $order, 'time, artist desc, name, album',
    'hidden asc nested transformation';

# exposed asc nested toggle
$order = SQL::OrderBy::toggle_resort(
    show_ascending => 1,
    selected => 'time',
    order_by => scalar SQL::OrderBy::toggle_resort(
        selected => 'artist',
        order_by => scalar SQL::OrderBy::toggle_resort(
            selected => 'artist',
            order_by => 'name, artist, album',
        )
    )
);
is $order, 'time asc, artist desc, name asc, album asc',
    'exposed asc nested transformation';
