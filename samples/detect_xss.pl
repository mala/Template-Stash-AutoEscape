#!/usr/local/bin/perl

use strict;
use lib qw(../lib);
use Template;
use Template::Stash::AutoEscape;

my $tmpl = join '', <DATA>;
my $html_class = Template::Stash::AutoEscape->class_for('HTML');

sub my_html_filter {
    my $text = shift;
    if ( ref $text eq $html_class ) {
        $text->escape_manually;
        return $text;
    }
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
    }
    return $text;
}

sub stringify_callback {
    my $self = shift;
    my $flag = $self->flag;
    if ( $flag == 1 ) {
        warn "escaped automatically: " . $self->[0];
    }
    elsif ( $flag == 2 ) {
        warn "escaped automatically and value changed: " . $self->[0];
    }
    $self->stop_callback;
}

my $stash = Template::Stash::AutoEscape->new({
    before_stringify => \&stringify_callback
});

my $tt = Template->new({
    STASH   => $stash,
    FILTERS => {
        html => \&my_html_filter,
    },
});

my $data = {
    string => "hoge",
    string2 => "<script>alert(1)</script>",
};

$tt->process( \$tmpl, $data, \my $output ) or die $tt->error;
print $output;

__DATA__
[% string | html %]
[% string2 | html %]
[% string %]
[% string2 %]

