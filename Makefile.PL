use 5.005;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'SQL::OrderBy',
    'VERSION_FROM' => 'OrderBy.pm',
    'PREREQ_PM'    => {},
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'OrderBy.pm',
           AUTHOR        => 'Gene Boggs <cpan@ology.net>')
        : ()),
);
