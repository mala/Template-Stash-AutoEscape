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

$Template::Stash::AutoEscape::DEBUG = 1;
my $stash = Template::Stash::AutoEscape->new({
    escape_type    => "HTML",    # default => HTML
    method_for_raw => "raw",     # default => raw
    ignore_escape => ["bold_allow_tag"],
});

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
    text        => as_html("hogehoge<b>text</b>"),
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

[% MACRO bold(text) BLOCK %]<b>aaa</b>[% END %]
[% MACRO bold_allow_tag(text) BLOCK %]<b>aaa</b>[% END %]

[% bold(text) %]
[% bold_allow_tag(text) %]

[% copy_html = html_string %]
[% copy_html | html %]

[% uri %] => http://example.com/?a=1&b=2
[% uri | html  %] => http://example.com/?a=1&amp;b=2
[% uri.as_string %] => http://example.com/?a=1&amp;b=2
[% uri.raw %] => http://example.com/?a=1&b=2
[% uri.host %] => example.com

[% uri2 = uri %]
[% uri == uri2 %]
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
