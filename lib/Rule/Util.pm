package Snowflake::Rule::Util;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(bash bash_strict);

=head2 bash($source)

Create a source from a Bash script. Bash will be taken from PATH when the
script is executed. This subroutine is useful when defining a build script
inline, as in figure 1.

Figure 1:

    Snowflake::Rule->new('Build main.c', [], {
        'main.c' => ['on_disk', 'main.c'],
        'snowflake-build' => bash(<<'BASH'),
            gcc -c main.c -o snowflake-output
BASH
    });

=cut

sub bash
{
    my ($source) = @_;
    ['inline', "#!/usr/bin/env bash\n$source"];
}

=head2 bash_strict($source)

Like C<bash>, but enable I<de facto> strict mode (C<set -euo pipefail>).

=cut

sub bash_strict
{
    my ($source) = @_;
    bash("set -euo pipefail\n$source");
}
