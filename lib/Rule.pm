package Snowflake::Rule;

use strict;
use warnings;

use Carp qw(confess croak);
use File::Basename qw(dirname);
use File::Path qw(mkpath rmtree);
use Snowflake::Hash qw(build_hash output_hash sources_hash);
use Snowflake::Log;

# Utility subroutine used for in-memory caching of hashes.
sub ensure
{
    my ($hash, $key, $value) = @_;
    if (exists($hash->{$key})) {
        $hash->{$key};
    } else {
        $hash->{$key} = $value->();
    }
}

=head2 Snowflake::Rule->new($name, \@dependencies, \%sources)

Create a rule with the given name, dependencies and sources.

The name is informative; it has no influence on any hashes or behavior of the
build system. Multiple rules may use the same name, although this is not
recommended as it is confusing.

Each dependency must be given as another rule. The order of dependencies is
significant; specifying them in a different order will give a rule with a
different build hash.

Each source must be given as an array reference of one of the following two
forms:

    # An inline source; a regular file that will appear in the scratch
    # directory with the given string as its contents.
    ['inline', '«contents»']

    # A path to a file relative to the directory the build system was invoked
    # from. The file will be copied to the scratch directory.
    ['on_disk', '«path»']

=cut

sub new
{
    my $cls          = shift;
    my $name         = shift;
    my @dependencies = shift->@*;
    my %sources      = shift->%*;
    my $self = {
        name         => $name,
        dependencies => \@dependencies,
        sources      => \%sources,
    };
    bless($self, $cls);
}

=head2 $rule->get_sources_hash()

Return the sources hash of the rule. For more information about the sources
hash, see the C<Snowflake::Hash::sources_hash> subroutine.

=cut

sub get_sources_hash
{
    my $self = shift;
    ensure($self, 'sources_hash', sub {
        my %sources = $self->{sources}->%*;
        sources_hash(%sources);
    });
}

=head2 $rule->get_build_hash($config)

Return the build hash of the rule. This will build the dependencies of the
rule if necessary, as the output hashes of the dependencies are needed to
compute the build hash of the dependent rule.

=cut

sub get_build_hash
{
    my ($self, $config) = @_;
    ensure($self, 'build_hash', sub {
        my $sources_hash = $self->get_sources_hash();
        my @dependency_output_hashes = map { $_->get_output_hash($config) }
                                           $self->{dependencies}->@*;
        build_hash($sources_hash, @dependency_output_hashes);
    });
}

=head2 $rule->get_output_hash($config)

Return the output hash of the rule. This will build the dependencies of the
rule if necessary, as well as the rule itself, as the output hash is computed
from the output of the rule.

=cut

sub get_output_hash
{
    my ($self, $config) = @_;
    ensure($self, 'output_hash', sub {
        $self->build($config);
    });
}

sub build
{
    my ($self, $config) = @_;

    # Extract configuration and inputs.
    my $rsync_path   = $ENV{SNOWFLAKE_RSYNC_PATH};
    my $name         = $self->{name};
    my $build_hash   = $self->get_build_hash($config);
    my @dependencies = $self->{dependencies}->@*;
    my %sources      = $self->{sources}->%*;

    # Check if already cached.
    my $cached = $config->get_cache($build_hash);
    if (defined($cached)) {
        my $output_path = $config->output_path($cached);
        Snowflake::Log::success("[CACHED] $name");
        Snowflake::Log::success("[CACHED] Output: $output_path");
        return $cached;
    }

    # Compute dependency paths. The order is important: it must be the same
    # order as those in the dependencies array. The build script expects them
    # to be in this order.
    my @dependency_paths = map {
        my $hash = $_->get_output_hash($config);
        # The path we return must be relative to the scratch directory, so we
        # prepend the appropriate number of ‘..’s.
        '../../../' . $config->output_path($hash);
    } @dependencies;

    # Create the scratch directory.
    my $scratch_path = $config->scratch_path($build_hash);
    rmtree($scratch_path, {safe => 1});
    mkpath($scratch_path);

    # Populate the scratch directory.
    for my $name (keys(%sources)) {
        my $path = "$scratch_path/$name";
        my ($type, $source) = $sources{$name}->@*;
        if ($type eq 'inline') {
            mkpath(dirname($path));
            open(my $file, '>', $path) or confess($!);
            print $file $source or confess($!);
            chmod(0755, $path) if ($name eq 'snowflake-build');
        } elsif ($type eq 'on_disk') {
            system($rsync_path, '--archive', '--relative', $source, $path)
                and croak('rsync');
        } else {
            croak("Bad source type: $type");
        }
    }

    # Execute build script in scratch directory.
    Snowflake::Log::info("[BUILD] $name");
    my $bash_path = $ENV{SNOWFLAKE_BASH_PATH};
    my $exit_status = system($bash_path, '-c', <<'BASH', '--', $scratch_path, @dependency_paths);
        set -o errexit
        cd "$1"
        exec ./snowflake-build "${@:2}" < /dev/null 2>&1 > snowflake-log
BASH
    if ($exit_status != 0) {
        Snowflake::Log::error("[FAILED] $name");
        Snowflake::Log::error("[FAILED] Status: $exit_status");
        Snowflake::Log::error("[FAILED] Logs: $scratch_path/snowflake-log");
        croak('snowflake-build');
    }

    # Copy output to stash.
    my $scratch_output_path = "$scratch_path/snowflake-output";
    my $output_hash = output_hash($scratch_output_path);
    my $output_path = $config->output_path($output_hash);
    mkpath(dirname($output_path));
    system($rsync_path, '--archive', $scratch_output_path, $output_path)
        and croak('rsync');

    # Add cache entry.
    $config->set_cache($build_hash, $output_hash);

    Snowflake::Log::success("[SUCCESS] $name");
    Snowflake::Log::success("[SUCCESS] Output: $output_path");

    # Return hash of output.
    $output_hash;
}

1;
