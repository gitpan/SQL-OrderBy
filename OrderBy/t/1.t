# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('SQL::OrderBy') };

#########################

my $order = SQL::OrderBy::toggle_resort(
    selected => 'artist',
    order_by => 'name, artist, album',
);
is $order, 'artist asc, name asc, album asc',
    'single transformation';

$order = SQL::OrderBy::toggle_resort(
    selected => 'time',
    order_by => SQL::OrderBy::toggle_resort(
        selected => 'artist',
        order_by => SQL::OrderBy::toggle_resort(
            selected => 'artist',
            order_by => 'name, artist, album'
        )
    )
);
is $order, 'time asc, artist desc, name asc, album asc',
    'nested transformation';
