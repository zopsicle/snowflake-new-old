use strict;
use warnings;

use Carp qw(croak);
use File::Spec;
use Snowflake::Config;

if (@ARGV != 1) {
    say STDERR 'Usage: snowflake RULESFILE';
    exit(1);
}
my $rules_file = File::Spec->rel2abs($ARGV[0]);

my @rules = do $rules_file;
if (@rules == 0) {
    if ($@ ne '') { croak($@); }
    if ($! ne '') { croak($!); }
    croak('Unknown error');
}

my $config = Snowflake::Config->new(stash_path => 'build');
$_->get_output_hash($config) for @rules;
