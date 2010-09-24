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
    escape_type    => "HTML",      # default => HTML
    method_for_raw => "raw",       # default => raw
    method_for_escape => "escape", # default => escape
    die_on_unescaped => 1,         # default => 0
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
       error => ['eval'],
};

sub templatize {
    my $input = $_[0];
}

run {
    my $block = shift;

    my $error_code = $tt->process( \($block->template), { data => $block->data }, \my $output );

    ok (($error_code xor $block->error()),
        $block->name . " - Error code and error agree",
    );

    if (! $block->error())
    {
        is( "$output", $block->expected, $block->name . ' output ok' );
    }
};

__DATA__

=== simple error
--- template
[% data %]
--- data eval
'<One&Two>'
--- expected
--- error
1
=== escape
--- template
[% data.escape %]
--- data eval
'<One&Two>'
--- expected
&lt;One&amp;Two&gt;
--- error
0
=== raw
--- template
[% data.raw %]
--- data eval
'<p>Hello &amp; Welcome!</p>'
--- expected
<p>Hello &amp; Welcome!</p>
--- error
0
