use inc::Module::Install;
name 'Template-Stash-AutoEscape';
all_from 'lib/Template/Stash/AutoEscape.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
auto_set_repository;
WriteAll;
