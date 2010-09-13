package Template::Stash::AutoEscape::Escaped::Base;
use strict;
use warnings;

use overload '""' => \&as_string;
use overload "."  => \&concat;
use overload "fallback" => 1;

sub ORIG ()    { 0 }
sub FLAG ()    { 1 }
sub ESCAPED()  { 2 }
sub CALLBACK() { 3 }

# Flag is:
#  0 or undef => Not escaped
#  1 => Escaped by automaticaly
#  2 => Escaped by automaticaly and value is changed!
#  3 => Escaped by manually
#  4 => Escaped by manually and value is changed!
#  other => user defined

sub new {
    my $class = shift;
    # $str, $flag, $escaped, $callback) = @_;
    my $self = bless [ @_ ], $class;
    $self
}

sub new_as_escaped {
    my $class = shift;
    my $self = bless [ $_[0], "new_as_escaped", $_[0] ], $class;
    $self
}

sub flag {
    my ($self, $flag) = @_;
    if ($flag) {
        return $self->[FLAG] = $flag;
    }
    $self->[FLAG];
}

sub escape {  
    # ABSTRACT METHOD
}

sub stop_callback {
    my $self = shift;
    $self->[CALLBACK] = undef;
}

sub escape_manually {
    my $self = shift;
    my $escaped_string = $self->escape($self->[ORIG]);
    $self->[ESCAPED] = $escaped_string;
    $self->[FLAG] = ($self->[ORIG] eq $escaped_string) ? 3 : 4;
    return $self;
}

sub as_string {
    my $self = shift;
   
    # already escaped 
    if ($self->[FLAG] && defined $self->[ESCAPED]) {
        $self->[CALLBACK]->($self) if (defined $self->[CALLBACK]);
        return $self->[ESCAPED];
    }

    my $escaped_string = $self->escape($self->[ORIG]);
    $self->[ESCAPED] = $escaped_string;
    $self->[FLAG] = ($self->[ORIG] eq $escaped_string) ? 1 : 2;
    $self->[CALLBACK]->($self) if (defined $self->[CALLBACK]);
    return $self->[ESCAPED];
}

sub concat {
    my ( $self, $other, $reversed ) = @_;
    my $class = ref $self;
    if (defined $other && length $other && ref $other eq $class) {
        # warn "concat with EscapedHTML";
        my $newval = ($reversed) ? $other->as_string . $self->as_string : $self->as_string . $other->as_string;
        return bless [
            $newval, $self->[FLAG], $newval, $self->[CALLBACK]
        ], $class;
    }
    elsif (defined $other && length $other) {
        my $newval = ($reversed) ? $other . $self->as_string : $self->as_string . $other;
        return bless [
            $newval, $self->[FLAG], $newval, $self->[CALLBACK]
        ], $class;
    }
    else {
        return $self;
    }
}

1;

