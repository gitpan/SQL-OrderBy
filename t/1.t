use strict;
use Test::More tests => 6;

BEGIN { use_ok('SQL::OrderBy') };

# Set context.
my $clause_string = 'name, artist, album';
my $column = 'artist';
my $result = 'artist asc, name asc, album asc';

# Scalar context
my $order = SQL::OrderBy::toggle_resort(
    selected => $column,
    order_by => $clause_string,
);
is $order, $result,
    'order clause in scalar context';
$order = SQL::OrderBy::toggle_resort(
    selected => $column,
    order_by => [ qw(name artist album) ],
);
is $order, $result,
    'order array in scalar context';

# Array context
my @order = SQL::OrderBy::toggle_resort(
    selected => $column,
    order_by => $clause_string,
);
is join (', ', @order), $result,
    'order clause in array context';
@order = SQL::OrderBy::toggle_resort(
    selected => $column,
    order_by => [ qw(name artist album) ],
);
is join (', ', @order), $result,
    'order array in array context';

# Nested transformation
$order = SQL::OrderBy::toggle_resort(
    selected => 'time',
    order_by => scalar SQL::OrderBy::toggle_resort(
        selected => $column,
        order_by => scalar SQL::OrderBy::toggle_resort(
            selected => $column,
            order_by => $clause_string
        )
    )
);
is $order, 'time asc, artist desc, name asc, album asc',
    'nested transformation';
