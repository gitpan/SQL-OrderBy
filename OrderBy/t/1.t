# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 6;
BEGIN { use_ok('SQL::OrderBy') };

#########################

my $clause_string = 'name, artist, album';
my $column = 'artist';
my $result = 'artist asc, name asc, album asc';

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
