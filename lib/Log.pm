package Snowflake::Log;

use strict;
use warnings;

use Term::ANSIColor qw(:constants);

sub info
{
    my ($message) = @_;
    $message =~ s/^\[[^\]]*\]/BLUE . $& . RESET/e;
    say STDERR $message;
}

sub success
{
    my ($message) = @_;
    $message =~ s/^\[[^\]]*\]/GREEN . $& . RESET/e;
    say STDERR $message;
}

sub error
{
    my ($message) = @_;
    $message =~ s/^\[[^\]]*\]/RED . $& . RESET/e;
    say STDERR $message;
}

1;
