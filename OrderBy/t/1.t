# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 6;
BEGIN { use_ok('SQL::OrderBy') };

#########################

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

$order = SQL::OrderBy::toggle_resort(
    selected => 'time',
    order_by => scalar SQL::OrderBy::toggle_resort(
        selected => 'artist',
        order_by => scalar SQL::OrderBy::toggle_resort(
            selected => 'artist',
            order_by => 'name, artist, album'
        )
    )
);
is $order, 'time asc, artist desc, name asc, album asc',
    'nested transformation';
