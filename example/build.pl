use strict;
use warnings;

use Snowflake::Rule;

my $compile_hello = Snowflake::Rule->new(
    'Compile hello.c',
    [],
    {
        'snowflake-build' => ['inline', "#!/usr/bin/env bash\n". <<'BASH'],
            set -o errexit
            mkdir snowflake-output
            gcc -o snowflake-output/hello.o -c hello.c
BASH
        'hello.h' => ['on_disk', 'example/hello.h'],
        'hello.c' => ['on_disk', 'example/hello.c'],
    },
);

my $compile_main = Snowflake::Rule->new(
    'Compile main.c',
    [],
    {
        'snowflake-build' => ['inline', "#!/usr/bin/env bash\n" . <<'BASH'],
            set -o errexit
            mkdir snowflake-output
            gcc -o snowflake-output/main.o -c main.c
BASH
        'hello.h' => ['on_disk', 'example/hello.h'],
        'main.c' => ['on_disk', 'example/main.c'],
    },
);

my $link = Snowflake::Rule->new(
    'Link',
    [$compile_hello, $compile_main],
    {
        'snowflake-build' => ['inline', "#!/usr/bin/env bash\n" . <<'BASH'],
            set -o errexit
            mkdir snowflake-output
            gcc -o snowflake-output/hello $1/hello.o $2/main.o
BASH
    },
);

$link;
