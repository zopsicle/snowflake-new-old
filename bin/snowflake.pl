use strict;
use warnings;

use Snowflake::Config;
use Snowflake::Hash qw(build_hash output_hash sources_hash);
use Snowflake::Rule;

my $config = Snowflake::Config->new(stash_path => 'build');

my $rule1 = Snowflake::Rule->new(
    'Rule 1',
    [],
    {
        'snowflake-build' => ['inline', "#!/bin/sh\ntac default.nix | tee snowflake-output"],
        'default.nix' => ['on_disk', 'default.nix'],
    },
);

my $rule2 = Snowflake::Rule->new(
    'Rule 2',
    [$rule1],
    {
        'snowflake-build' => ['inline', "#!/usr/bin/env bash\ncat \"\$\@\"\ntouch snowflake-output"],
    },
);

my $target = $rule2;
my $sources_hash = $target->get_sources_hash();
my $build_hash   = $target->get_build_hash($config);
my $output_hash  = $target->get_output_hash($config);

CORE::say "Sources hash: $sources_hash";
CORE::say "Build hash:   $build_hash";
CORE::say "Output hash:  $output_hash";
