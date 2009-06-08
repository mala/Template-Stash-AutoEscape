package Template::Stash::AutoEscape;

use strict;
use warnings;
our $VERSION = '0.01';

use Template::Config;
use base ($Template::Config::STASH, 'Class::Data::Inheritable');

use UNIVERSAL::require;
use Template::Stash::AutoEscape::RawString;

__PACKAGE__->mk_classdata('class_for_type');
__PACKAGE__->class_for_type({
    HTML => __PACKAGE__ . '::Escaped::HTML', 
});

our $DEBUG = 0;
our $escape_count = 0;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{method_for_raw} ||= 'raw';
    $self->{escape_type} ||= 'HTML';
    $self->{_raw_string_class} ||= __PACKAGE__ . '::' . 'RawString';
    my $escape_class = $class->class_for($self->{escape_type});
    if (!$escape_class->can("escape")) {
        $escape_class->require or die $@;
    }
   
    $Template::Stash::SCALAR_OPS->{$self->{method_for_raw}} = sub {
        my $scalar = shift;
        $self->{_raw_string_class}->new($scalar);
    };
    return $self;
}

sub get {
    my ( $self, @args ) = @_;
    my ($var) = $self->SUPER::get(@args);
    my $ref = ref $var;
    # string
    unless ($ref) {
        $escape_count++ if $DEBUG;
        return $self->escape($var);
    }
    # via .raw vmethod
    if ($ref eq $self->{_raw_string_class}) {
        return "$var";
    }
    my $escape_class = $self->class_for($self->{escape_type});
    if (!$ref->isa($escape_class)) {
        $escape_count++ if $DEBUG;
        return $self->escape($var);
    }
    return $var;
}

sub class_for {
    my $class = shift;
    if (@_ == 1) {
        return $class->class_for_type->{$_[0]} || __PACKAGE__ . '::Escaped::' . $_[0];
    } elsif (@_ == 2) {
        return $class->class_for_type->{$_[0]} = $_[1]; 
    }
}

sub escape {
    my $self = shift;
    my $text  = shift;
    my $class = $self->class_for($self->{escape_type});
    $class->escape($text);
}

sub escape_count {
    $escape_count;
}

1;


__END__

=head1 NAME

Template::Stash::AutoEscape - escape automatically in Template-Toolkit.

=head1 SYNOPSIS

  use Template::Stash::AutoEscape;

=head1 METHODS

=head2 new

=over 2

=item escape_type

default is HTML

=item method_for_raw

default is raw

=back

=head2 class_for

    Template::Stash::AutoEscape->class_for("HTML") # Template::Stash::AutoEscape::Escaped::HTML
    Template::Stash::AutoEscape->class_for("HTML" => "MyHTMLString");

=back

=head1 DESCRIPTION

Template::Stash::AutoEscape is a sub class of L<Template::Stash>,


=head1 AUTHOR

mala E<lt>cpan@ma.laE<gt>

=head1 SEE ALSO

L<Template>, L<Template::Stash::EscapedHTML>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
