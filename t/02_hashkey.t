use Test::Base;

plan 'no_plan';

use URI;
use Template::Stash::AutoEscape;
use Template::Stash::AutoEscape::Escaped::HTML;
# $Template::Stash::AutoEscape::DEBUG = 1;

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
    # local $SIG{__WARN__} = sub { $warning = join ' ', @_ };

    $tt->process( \($block->template), { data => $block->data }, \my $output )
        or die $tt->error;

    if ($warning) {
        my $expected = $block->warn;
        like( $warning, $expected, $block->name . ' warning ok' );
    }

    is( "$output", $block->expected, $block->name . ' output ok' );
};

__DATA__

=== [% hash.${key} %]
--- template
[% SET key = '<key>' %][% data.${key} %]
--- data eval
+{ "<key>" => "<value>" }
--- expected
&lt;value&gt;

=== [% hash.key %]
--- template
[% data.key %]
--- data eval
+{ "key" => "<value>" }
--- expected
&lt;value&gt;

=== [% hash.item(key) %]
--- template
[% SET key = '<key>' %][% data.item(key) %]
--- data eval
+{ "<key>" => "<value>", "&lt;key&gt;" => "hoge" }
--- expected
&lt;value&gt;

=== [% hash.item(key.raw) %]
--- template
[% SET key = '<key>' %][% data.item(key.raw) %]
--- data eval
+{ "<key>" => "<value>", "&lt;key&gt;" => "hoge" }
--- expected
&lt;value&gt;

=== [% hash.key.raw %]
--- template
[% data.key.raw %]
--- data eval
+{ "key" => "<value>" }
--- expected
<value>




