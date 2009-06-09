#!/usr/local/bin/perl

use strict;
use Template;

use lib qw(../lib);
use Template::Stash::AutoEscape;
use Template::Stash::AutoEscape::Escaped::HTML;

my $tmpl = join '', <DATA>;

my $html_class = Template::Stash::AutoEscape->class_for('HTML');

sub my_html_filter {
    my $text = shift;
    if ( ref $text eq $html_class ) {
        warn "already escaped: " . $text;
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

my $stash = Template::Stash::AutoEscape->new(
    escape_type    => "HTML",    # default => HTML
    method_for_raw => "raw",     # default => raw
);

use URI;
use DateTime;
my $tt = Template->new(
    {
        STASH   => $stash,
        FILTERS => { html => \&my_html_filter, },
    }
);

#warn $uri->host;


my $data = {
    uri         => URI->new("http://example.com/?a=1&b=2"),
    date        => DateTime->now,
    array       => [qw(<b> <a> </a>)],
    string      => "<b>hoge</b>",
    html_string => as_html("<b>hoge</b>"),
    object      => {
        hoge   => "<b>hoge</b>",
        method => sub {
            "<b>method</b>";
          }
    },
};

sub as_html {
    Template::Stash::AutoEscape->class_for('HTML')->new( $_[0] );
}

$tt->process( \$tmpl, $data, \my $output ) or die $tt->error;
print $output;

__DATA__
<html>

[% copy_html = html_string %]
[% copy_html | html %]

[% uri %]
[% uri | html  %]
[% uri.as_string %]
[% uri.raw %]
[% uri.host %]

[% uri2 = uri %]
[% uri2 %]
[% uri2.host %]

[% html_string %] => <b>hoge</b>
[% html_string | html %] => <b>hoge</b>

[% string %] => &lt;b&gt;hoge&lt;/b&gt;
[% string | html %] => &lt;b&gt;hoge&lt;/b&gt;
[% string.raw %] => <b>hoge</b>
[% string.raw | html %] => &lt;b&gt;hoge&lt;/b&gt;

[% object.hoge %] => &lt;b&gt;hoge&lt;/b&gt;
[% object.method %] => &lt;b&gt;method&lt;/b&gt;
[% object.hoge.raw %] => <b>hoge</b>
[% object.method.raw %] => <b>method</b>

</html>
