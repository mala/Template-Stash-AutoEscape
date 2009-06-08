package Template::Stash::AutoEscape::RawString;
use strict;
use warnings;
use overload '""' => \&as_string;

sub new {
    my ( $klass, $str ) = @_;
    bless \$str, $klass;
}

sub as_string {
    my $self = shift;
    return $$self;
}

1;
