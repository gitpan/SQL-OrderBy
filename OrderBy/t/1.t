# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('SQL::OrderBy') };

#########################

my $order = resort(
    order_by => 'name, artist, album',
    selected => 'artist',
);
is $order, 'artist asc, name asc, album asc',
    'single transformation';

$order = resort(
    order_by => resort(
        order_by => resort(
            order_by => 'name, artist, album',
            selected => 'artist',
        ),
        selected => 'artist',
    ),
    selected => 'time',
);
is $order, 'time asc, artist desc, name asc, album asc',
    'nested transformation';
