# These two lines enable strict mode and warnings. They are very helpful when
# programming in Perl.
use strict;
use warnings;

# Import the modules that allow us to define rules.
use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

# A rule describes how to build something.
my $compile_hello = Snowflake::Rule->new(
    # The name of a rule is informative; it is shown to the user in the build
    # logs. It is not otherwise used.
    name => 'Compile hello.c',

    # The dependencies of a rule are given as an array of other rules. The
    # dependencies are built prior to the rule itself being built, and are
    # passed to the build script as arguments.
    dependencies => [],

    # The sources are files that are made available to the build script. Files
    # can be specified as “inline” or as “on disk”.
    sources => {
        # The file named snowflake-build is special: it is the build script
        # that actually builds things.
        'snowflake-build' => bash_strict(<<~'BASH'),
            # The build script must place its output in the file named
            # snowflake_output. This is typically a directory, but it does not
            # have to be one.
            mkdir snowflake-output

            gcc -o snowflake-output/hello.o -c hello.c
            BASH
        # Source files are passed in as well.
        'hello.h' => ['on_disk', 'example/hello.h'],
        'hello.c' => ['on_disk', 'example/hello.c'],
    },
);

my $compile_main = Snowflake::Rule->new(
    name => 'Compile main.c',
    dependencies => [],
    sources => {
        'snowflake-build' => bash_strict(<<~'BASH'),
            mkdir snowflake-output
            gcc -o snowflake-output/main.o -c main.c
            BASH
        'hello.h' => ['on_disk', 'example/hello.h'],
        'main.c' => ['on_disk', 'example/main.c'],
    },
);

my $link = Snowflake::Rule->new(
    name => 'Link',
    dependencies => [$compile_hello, $compile_main],
    sources => {
        'snowflake-build' => bash_strict(<<~'BASH'),
            gcc -o snowflake-output $1/hello.o $2/main.o
            BASH
    },
);

# A mapping from aliases to rules is returned. This mapping is known as the
# collection of artifacts. Artifacts are made available in the build/artifact
# directory for the user’s convenience, so they don’t have to worry about
# cryptographic hashes all the time.
hello => $link;
