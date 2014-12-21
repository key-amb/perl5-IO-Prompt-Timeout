package IO::Prompt::Timeout;
use 5.006;
use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw(prompt);

use Carp ();

our $VERSION = "0.01";

my $DEFAULT_TIMEOUT_SEC = 30;

sub prompt {
    my $message = shift;
    unless ($message) {
        Carp::croak(q["prompt" called without any argument!]);
    }
    my %opt = _parse_args(@_);

    my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;

    my $default_answer = exists $opt{default_answer} ? $opt{default_answer} : q{};
    my $dispdef = $default_answer ? "[$default_answer]" : q{ };

    local $| = 1;
    local $\;
    print "$message $dispdef";

    my $answer;
    if ($ENV{PERL_MM_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
        print "$default_answer\n";
    } else {
        local $SIG{ALRM} = sub { die 'Prompt timed out.' };
        my $timeout = $opt{timeout} || $DEFAULT_TIMEOUT_SEC;
        alarm $timeout;
        $answer = <STDIN>;
        alarm 0;
        if (defined $answer) {
            chomp $answer;
        } else {    # user hit ctrl-D
            print "\n";
        }
    }

    $answer = defined $answer ? $answer : q{};
    return $answer || $default_answer;
}

sub _parse_args {
    my %opt;
    if (@_ % 2 == 1) {
        $opt{default_answer} = shift;
    }
    %opt = (%opt, @_);
    return %opt;
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

