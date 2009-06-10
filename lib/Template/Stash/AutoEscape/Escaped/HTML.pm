package Template::Stash::AutoEscape::Escaped::HTML;
use strict;
use warnings;
use base qw(Template::Stash::AutoEscape::Escaped::Base);

sub escape {
    my $class = shift;
    my $text = shift;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
    }
    return $text;
    # return $class->new($text, 1);
}

1;

