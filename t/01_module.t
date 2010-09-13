use Test::Base;

plan 'no_plan';

use URI;
use Template::Stash::AutoEscape;
use Template::Stash::AutoEscape::Escaped::HTML;

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

sub as_html {
    Template::Stash::AutoEscape->class_for('HTML')->new_as_escaped( $_[0] );
}

my $stash = Template::Stash::AutoEscape->new(
    escape_type    => "HTML",    # default => HTML
    method_for_raw => "raw",     # default => raw
);

my $tt = Template->new(
    {
        STASH   => $stash,
        FILTERS => { html => \&my_html_filter, },
    }
);

filters {
    template => ['chomp'],
        data => ['chomp'],
    expected => ['chomp'],
};

sub templatize {
    my $input = $_[0];
}

run {
    my $block = shift;

    my $warning;
    local $SIG{__WARN__} = sub { $warning = join ' ', @_ };

    $tt->process( \($block->template), { data => $block->data }, \my $output )
        or die $tt->error;

    if ($warning) {
        my $expected = $block->warn;
        like( $warning, $expected, $block->name . ' warning ok' );
    }

    is( "$output", $block->expected, $block->name . ' output ok' );
};

__DATA__

=== [% uri %]
--- template
[% data %]
--- data eval
URI->new('http://example.com/?a=1&b=2')
--- expected
http://example.com/?a=1&b=2

=== [% uri.as_string %]
--- template
[% data.as_string %]
--- data eval
URI->new('http://example.com/?a=1&b=2')
--- expected
http://example.com/?a=1&amp;b=2

=== [% uri | html %]
--- template
[% data | html %]
--- data eval
URI->new('http://example.com/?a=1&b=2')
--- expected
http://example.com/?a=1&amp;b=2
--- warn regexp
already escaped: http://example\.com/\?a=1&amp;b=2

=== [% html_string %]
--- template
[% data %]
--- data as_html
<b>hoge</b>
--- expected
<b>hoge</b>

=== [% html_string | html %]
--- template
[% data | html %]
--- data as_html
<b>hoge</b>
--- expected
<b>hoge</b>
--- warn regexp
already escaped: <b>hoge</b>

=== [% string %]
--- template
[% data %]
--- data
<b>hoge</b>
--- expected
&lt;b&gt;hoge&lt;/b&gt;

=== [% string | html %]
--- template
[% data | html %]
--- data
<b>hoge</b>
--- expected
&lt;b&gt;hoge&lt;/b&gt;
--- warn regexp
already escaped: &lt;b&gt;hoge&lt;/b&gt;

=== [% string.raw %]
--- template
[% data.raw %]
--- data
<b>hoge</b>
--- expected
<b>hoge</b>

=== [% string.raw | html %]
--- template
[% data.raw | html %]
--- data
<b>hoge</b>
--- expected
&lt;b&gt;hoge&lt;/b&gt;

=== [% object.hoge %]
--- template
[% data.hoge %]
--- data eval
{ hoge => '<b>hoge</b>' }
--- expected
&lt;b&gt;hoge&lt;/b&gt;


=== [% object.method %]
--- template
[% data.method %]
--- data eval
{ method => sub { '<b>method</b>' } }
--- expected
&lt;b&gt;method&lt;/b&gt;


=== [% object.hoge.raw %]
--- template
[% data.hoge.raw %]
--- data eval
{ hoge => '<b>hoge</b>' }
--- expected
<b>hoge</b>


=== [% object.method.raw %]
--- template
[% data.method.raw %]
--- data eval
{ method => sub { '<b>method</b>' } }
--- expected
<b>method</b>

=== [% string %][% 0 %]
--- template
[% data %][% 0 %]
--- data
<b>hoge</b>
--- expected
&lt;b&gt;hoge&lt;/b&gt;0
