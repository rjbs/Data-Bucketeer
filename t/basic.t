use strict;
use warnings;
use Test::More;

use Test::Fatal;

use Data::Bucketeer;

sub buck_ok {
  my ($desc, $buck_args, $expect) = @_;

  my @buck_args = ref $buck_args eq 'ARRAY' ? @$buck_args : $buck_args;
  my $buck = Data::Bucketeer->new(@buck_args);

  subtest $desc => sub {
    for my $input (sort { $a <=> $b } keys %$expect) {
      my $this_expect = $expect->{$input};

      if (ref $this_expect and ref $this_expect eq 'ARRAY') {
        my ($bound, $label) = @{ $expect->{$input} };
        my $label_str = defined $label ? $label : '(undef)';

        is(
          $buck->label_for($input),
          $label,
          sprintf("%8s -> label %s", $input, $label_str),
        );

        is_deeply(
          [ $buck->bound_and_label_for($input) ],
          [ $bound, $label ],
          sprintf("%8s -> bound and label", $input),
        );
      } else {
        my $error = exception { $buck->label_for($input) };

        if (! ref $this_expect and ! defined $this_expect) {
          is($error, $this_expect, "no exception for $input");
        } elsif (! ref $this_expect) {
          is($error, $this_expect, "string eq exception for $input");
        } elsif (ref $this_expect eq 'Regexp') {
          like($error, $this_expect, "regexp match exception for $input");
        } elsif (ref $this_expect eq 'CODE') {
          ok($this_expect->($error), "code check exception for $input");
        } else {
          Carp::confess("don't know what to do with $this_expect expectation");
        }
      }
    }
  };
}

buck_ok(
  "my first test case",
  {
    10 => 'foo',
    20 => 'bar',
    30 => 'baz',
    40 => sub { "xyz$_" },
    50 => sub { die "> 50 is not permitted\n" },
  },
  {
    -Inf   => [ undef, undef ],
      -1   => [ undef, undef ],
       0   => [ undef, undef ],
       1   => [ undef, undef ],
      10   => [ undef, undef ],
      11   => [    10, 'foo' ],
      20   => [    10, 'foo' ],
      20.1 => [    20, 'bar' ],
      21   => [    20, 'bar' ],
      31   => [    30, 'baz' ],
      40.1 => [    40, 'xyz40.1' ],
      41   => [    40, 'xyz41' ],
      50   => [    40, 'xyz50' ],
      51   => qq{> 50 is not permitted\n},
  },
);

buck_ok(
  "the > operator",
  [
    '>' => {
      10 => 'foo',
      20 => 'bar',
      30 => 'baz',
      40 => sub { "xyz$_" },
      50 => sub { die "> 50 is not permitted\n" },
    },
  ],
  {
    -Inf   => [ undef, undef ],
      -1   => [ undef, undef ],
       0   => [ undef, undef ],
       1   => [ undef, undef ],
      10   => [ undef, undef ],
      11   => [    10, 'foo' ],
      20   => [    10, 'foo' ],
      20.1 => [    20, 'bar' ],
      21   => [    20, 'bar' ],
      31   => [    30, 'baz' ],
      40.1 => [    40, 'xyz40.1' ],
      41   => [    40, 'xyz41' ],
      50   => [    40, 'xyz50' ],
      51   => qq{> 50 is not permitted\n},
  },
);

buck_ok(
  "the >= operator",
  [
    '>=' => {
      10 => 'foo',
      20 => 'bar',
      30 => 'baz',
      40 => sub { "xyz$_" },
      50 => sub { die ">= 50 is not permitted\n" },
    },
  ],
  {
    -Inf   => [ undef, undef ],
      -1   => [ undef, undef ],
       0   => [ undef, undef ],
       1   => [ undef, undef ],
      10   => [    10, 'foo',],
      11   => [    10, 'foo' ],
      20   => [    20, 'bar' ],
      20.1 => [    20, 'bar' ],
      21   => [    20, 'bar' ],
      31   => [    30, 'baz' ],
      40.1 => [    40, 'xyz40.1' ],
      41   => [    40, 'xyz41' ],
      50   => qq{>= 50 is not permitted\n},
      51   => qq{>= 50 is not permitted\n},
  },
);


done_testing;
