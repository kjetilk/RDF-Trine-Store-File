use inc::Module::Install;

name     'RDF-Trine-Store-File';
all_from 'lib/RDF/Trine/Store/File.pm';
author   q{Kjetil Kjernsmo <kjetilk@cpan.org>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

