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

$rule2->get_output_hash($config);
