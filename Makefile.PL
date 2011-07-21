use inc::Module::Install;

name     'RDF-Trine-Store-File';
all_from 'lib/RDF/Trine/Store/File.pm';
readme_from 'lib/RDF/Trine/Store/File.pm';
author   q{Kjetil Kjernsmo <kjetilk@cpan.org>};
license  'perl';

test_requires 'Test::More';

requires 'RDF::Trine';
requires 'File::Temp';
requires 'File::Util';


author_tests('xt');

auto_set_repository;
auto_set_bugtracker;

write_doap_changes;

sign;

WriteAll;

