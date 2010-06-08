use inc::Module::Install;
name 'Template-Stash-AutoEscape';
all_from 'lib/Template/Stash/AutoEscape.pm';

# requires '';

tests 't/*.t';
# author_tests 'xt';

requires 'Class::Data::Inheritable';
requires 'UNIVERSAL::require';
requires 'Template::Toolkit';

build_requires 'Test::More';
use_test_base;
auto_include;
auto_set_repository;
WriteAll;
