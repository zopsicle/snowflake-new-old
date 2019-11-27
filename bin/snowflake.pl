use v5.10;

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

my %artifacts = do $rules_file;
if (keys(%artifacts) == 0) {
    if ($@ ne '') { croak($@); }
    if ($! ne '') { croak($!); }
    croak('Unknown error');
}

my $config = Snowflake::Config->new(stash_path => 'build');
for my $alias (keys(%artifacts)) {
    my $rule = $artifacts{$alias};
    my $output_hash = $rule->get_output_hash($config);
    $config->set_artifact($alias, $output_hash);
}
