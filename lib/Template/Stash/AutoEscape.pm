package Template::Stash::AutoEscape;

use strict;
use warnings;
our $VERSION = '0.03';

use Template::Config;
use base ($Template::Config::STASH, 'Class::Data::Inheritable');

use Data::Dumper;
use UNIVERSAL::require;
use Template::Stash::AutoEscape::RawString;

__PACKAGE__->mk_classdata('class_for_type');
__PACKAGE__->class_for_type({
    HTML => __PACKAGE__ . '::Escaped::HTML',
    YourCode => __PACKAGE__ . '::Escaped::YourCode',
});

our $DEBUG = 0;
our $escape_count = 0;

our $ESCAPE_ARGS = 0;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{method_for_raw} ||= 'raw';
    $self->{_raw_string_class} ||= __PACKAGE__ . '::' . 'RawString';
    $self->{ignore_escape} ||= [];

    if (ref $self->{escape_method} eq "CODE") {
        $self->{escape_type} = "YourCode";
        my $escape_class = $class->class_for($self->{escape_type});
        if (!$escape_class->can("escape")) {
            $escape_class->require or die $@;
        }
        $escape_class->escape_method($self->{escape_method});
    } else {
        $self->{escape_type} ||= 'HTML';
        my $escape_class = $class->class_for($self->{escape_type});
        if (!$escape_class->can("escape")) {
            $escape_class->require or die $@;
        }
    }
    
    $Template::Stash::SCALAR_OPS->{$self->{method_for_raw}} = sub {
        my $scalar = shift;
        $self->{_raw_string_class}->new($scalar);
    };
    $Template::Stash::LIST_OPS->{$self->{method_for_raw}} = sub {
        my $scalar = shift;
        $self->{_raw_string_class}->new($scalar);
    };
    return $self;
}

sub get_raw_args {
    my ( $args, $escaped_class ) = @_;
    my $changed = 0;
    my @raw_args;
    for my $v (@{ $args }) {
        my $new_v;
        if ( ref $v eq $escaped_class ) {
            $changed = 1;
            $new_v = $v->[0];
        } elsif (ref $v eq 'ARRAY') {
            $new_v = get_raw_args($v, $escaped_class);
            if ($new_v) {
                $changed = 1;
            } else {
                $new_v = $v;
            }
        } else {
            $new_v = $v;
        }
        push @raw_args, $new_v;
    }

    return unless $changed;
    return \@raw_args;
}

sub get {
    my ( $self, @args ) = @_;
    # get value
    warn Dumper +{ args => \@args } if $DEBUG;

    # note: hack for [% hash.${key} %] [% hash.item(key) %] 
    # key expected raw string.
    if (!$ESCAPE_ARGS && ref $args[0] eq "ARRAY" && (scalar @{$args[0]} > 2)){
        my $escaped_class = $self->class_for($self->{escape_type});
        my $changed = get_raw_args($args[0], $escaped_class);
        # retry by non-escaped args
        if ($changed) {
            $args[0] = $changed;
            return $self->get(@args);
        }
    }

    my ($var) = $self->SUPER::get(@args);
    if (ref $args[0] eq "ARRAY") {
        my $key = $args[0]->[0];
        warn $key if $DEBUG;
        if (grep { $key eq $_ } @{ $self->{ignore_escape} }) {
            warn "ignore escape $key" if $DEBUG;
            return $var;
        }
    }

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
    return $var;
#    my $escape_class = $self->class_for($self->{escape_type});
#    warn $ref->isa($escape_class);
#    if (!$ref->isa($escape_class)) {
#        $escape_count++ if $DEBUG;
#        return $self->escape($var);
#    }
#    return $var;
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
    my $text = shift;
    my $class = $self->class_for($self->{escape_type});
    my $stringify_callback = $self->{before_stringify};
    $class->new($text, 0, undef, $stringify_callback);
}

sub escape_count {
    $escape_count;
}

1;


__END__

=head1 NAME

Template::Stash::AutoEscape - escape automatically in Template-Toolkit.

=head1 SYNOPSIS

  use Template;
  use Template::Stash::AutoEscape;
  my $tt = Template->new({
    STASH => Template::Stash::AutoEscape->new  
  });

=head1 METHODS

=head2 new

=over 2

=item escape_type

default is HTML

=item method_for_raw

default is raw, you can get not escaped value from [% value.raw %] 

=item escape_method

  my $tt = Template->new({
    STASH => Template::Stash::AutoEscape->new({
        escape_method => sub { my $text = shift; ... ; return $text }
    })
  });

=item ignore_escape  

  my $stash = Template::Stash::AutoEscape->new({ignore_escape => [qw(include_html include_raw my_escape_func)], ... );

  You can disable auto-escape for some value or TT-Macro.
  For example: include other component, for output safety html, using other escape method, etc.
  
=back

=head2 class_for

    Template::Stash::AutoEscape->class_for("HTML") # Template::Stash::AutoEscape::Escaped::HTML
    Template::Stash::AutoEscape->class_for("HTML" => "MyHTMLString");

=head1 DESCRIPTION

Template::Stash::AutoEscape is a sub class of L<Template::Stash>, automatically escape all HTML strings and avoid XSS vulnerability.

=head1 CONFIGURE

=over 2

=item $Template::Stash::AutoEscape::ESCAPE_ARGS

 default is 0. for example "key of hash" or "args of vmethods" are not escaped. I think this is good in most cases.
 [% hash.${key} %] [% hash.item(key) %] means [% hash.${key.raw} | html %] [% hash.item(key.raw) | html %] by default.

=head1 AUTHOR

mala E<lt>cpan@ma.laE<gt>

=head1 SEE ALSO

L<Template>, L<Template::Stash::EscapedHTML>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
