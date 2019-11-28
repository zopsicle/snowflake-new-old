use v5.10;

use strict;
use warnings;
use lib $ENV{SNOWFLAKE_LIB_PATH};

use Carp qw(confess);
use File::Spec;
use Snowflake::Config;

if (@ARGV != 1) {
    say STDERR 'Usage: snowflake RULESFILE';
    exit(1);
}
my $rules_file = File::Spec->rel2abs($ARGV[0]);

my $artifacts = do $rules_file;
unless (defined($artifacts)) {
    confess("do: $@") if $@ ne '';
    confess("do: $!") if $! ne '';
    confess('do: unknown error');
}

my %artifacts = $artifacts->%*;
my $config = Snowflake::Config->new('build');
for my $alias (keys(%artifacts)) {
    my $rule = $artifacts{$alias};
    my $output_hash = $rule->get_output_hash($config);
    $config->set_artifact($alias, $output_hash);
}
