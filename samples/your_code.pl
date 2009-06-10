#!/usr/local/bin/perl

use strict;
use lib qw(../lib);
use Template;
use Template::Stash::AutoEscape;

my $tmpl = join '', <DATA>;

my $stash = Template::Stash::AutoEscape->new({
    escape_method => sub {
        my $text = shift;
        $text =~s/'/&quot;/g;
        $text  
    },
});

my $tt = Template->new({
    STASH   => $stash,
});

my $data = {
    string => qq{"'hoge'"},
};

$tt->process( \$tmpl, $data, \my $output ) or die $tt->error;
print $output;

__DATA__
[% string %]
