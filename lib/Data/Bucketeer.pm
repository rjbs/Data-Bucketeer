use strict;
use warnings;
package Data::Bucketeer;
# ABSTRACT: sort data into buckets based on threshholds

use Carp qw(croak);
use Scalar::Util ();
use List::Util qw(first);

sub new {
  my ($class, @rest) = @_;
  unshift @rest, '>' if ref $rest[0];

  my ($type, $buckets) = @rest;

  my @non_num = grep { ! Scalar::Util::looks_like_number($_) or /NaN/i }
                keys %$buckets;
  croak "non-numeric bucket boundaries: @non_num" if @non_num;

  my $guts = bless {
    buckets => $buckets,
    picker  => $class->__picker_for($type),
  };

  return bless $guts => $class;
}

my %operator = (
  '>' => sub {
    my ($self, $this) = @_;
    first { $this > $_ } sort { $b <=> $a } keys %{ $self->{buckets} };
  },
  '>=' => sub {
    my ($self, $this) = @_;
    first { $this >= $_ } sort { $b <=> $a } keys %{ $self->{buckets} };
  },

  '<=' => sub {
    my ($self, $this) = @_;
    first { $this <= $_ } sort { $a <=> $b } keys %{ $self->{buckets} };
  },
  '<' => sub {
    my ($self, $this) = @_;
    first { $this < $_ } sort { $a <=> $b } keys %{ $self->{buckets} };
  },
);

sub __picker_for {
  my ($self, $type) = @_;
  return($operator{ $type } || croak("unknown bucket operator: $type"));
}

sub label_for {
  my ($self, $input) = @_;

  my ($bound, $label) = $self->bound_and_label_for($input);

  return $label;
}

sub bound_and_label_for {
  my ($self, $input) = @_;

  my $bound = $self->{picker}->($self, $input);
  return (undef, undef) unless defined $bound;

  my $bucket = $self->{buckets}->{$bound};
  my $label = ref $bucket
            ? do { local $_ = $input; $bucket->($input) }
            : $bucket;

  return ($bound, $label);
}

1;
