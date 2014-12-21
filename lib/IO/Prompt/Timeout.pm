package IO::Prompt::Timeout;
use 5.006;
use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw(prompt has_timed_out);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Carp ();

our $VERSION = "0.01";

my $HAS_TIMED_OUT;
my $DEFAULT_TIMEOUT_SEC = 60;

sub prompt {
    my $message = shift;
    unless ($message) {
        Carp::croak(q["prompt" called without any argument!]);
    }

    # Clear timeout info.
    undef $HAS_TIMED_OUT;

    my %opt = _parse_args(@_);

    my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;

    my $default_answer = exists $opt{default_answer} ? $opt{default_answer} : q{};
    my $dispdef = $default_answer ? "[$default_answer]" : q{ };

    local $| = 1;
    local $\;
    print "$message $dispdef";

    my $answer;
    if ($ENV{PERL_IOPT_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
        print "$default_answer\n";
    } else {
        my $alarm_error = "__ALARM__\n";
        local $SIG{ALRM} = sub { die $alarm_error; };
        my $timeout = $opt{timeout} || $DEFAULT_TIMEOUT_SEC;
        eval {
            alarm $timeout;
            $answer = <STDIN>;
            alarm 0;
        };
        if ($@) {
            unless ($@ eq $alarm_error) {
                Carp::croak("Unexpected error while waiting prompt input! ERROR:$@");
            }
            $HAS_TIMED_OUT = 1;
        }

        if (defined $answer) {
            chomp $answer;
        } else {
            # User hit ctrl-D
            # Or timed out.
            print "\n";
        }
    }

    $answer = defined $answer ? $answer : q{};
    return $answer || $default_answer;
}

sub has_timed_out { $HAS_TIMED_OUT; }

sub _parse_args {
    my %args = @_;
    return (
        default_answer => $args{default},
        timeout        => $args{timeout},
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

IO::Prompt::Timeout - It's new $module

=head1 SYNOPSIS

    use IO::Prompt::Timeout;

=head1 DESCRIPTION

IO::Prompt::Timeout is ...

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

