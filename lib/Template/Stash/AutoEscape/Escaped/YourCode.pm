package Template::Stash::AutoEscape::Escaped::YourCode;
use strict;
use warnings;
use base qw(Template::Stash::AutoEscape::Escaped::Base Class::Data::Inheritable);
__PACKAGE__->mk_classdata('escape_method');

sub escape {
    my $class = shift;
    my $text = shift;
    $class->escape_method->($text);
}

1;

