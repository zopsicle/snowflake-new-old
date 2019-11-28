=head1 NAME

Snowflake::Rule::Mercury - Rules for Mercury.

=head1 SYNOPSIS

    use Snowflake::Rule::Mercury qw(mercury_executable mercury_module);

    # Compile modules to .int* and .o files.
    my $module_a = mercury_module(
        name => 'module_a',
        source => 'module_a.m',
        dependencies => [],
    );
    my $module_b = mercury_module(
        name => 'module_b',
        source => 'module_b.m',
        dependencies => [$module_a],
    );

    # Link .o files to an executable.
    my $example = mercury_executable(
        name => 'example',
        modules => [$module_a, $module_b],
    );

=head1 DESCRIPTION

=cut

package Snowflake::Rule::Mercury;

use Exporter qw(import);
use Snowflake::Rule::Util qw(bash_strict);
use Snowflake::Rule;

our @EXPORT_OK = qw(mercury_executable mercury_module);

# Utility function for finding transitive dependencies of a module, and the
# module itself. Mercury needs all the interface files like that.
sub recursive_interfaces
{
    my $self         = $_[0]->{interface};
    my @dependencies = map { recursive_interfaces($_) }
                           $_[0]->{dependencies}->@*;
    # TODO: Eliminate duplicates for efficiency.
    $self, @dependencies;
}

=head2 mercury_module(name => $name, source => $source, dependencies => \@dependencies)

Return an opaque object containing rules for compiling a Mercury module named
C<$name> defined in C<$source>. C<\@dependencies> must refer to an array of
other such objects.

=cut

sub mercury_module
{
    my %options      = @_;
    my $name         = $options{name};
    my $source       = $options{source};
    my @dependencies = $options{dependencies}->@*;

    my $interface = Snowflake::Rule->new(
        name => "Mercury interface ‘$name’",
        dependencies => [map { recursive_interfaces($_) } @dependencies],
        sources => {
            'NAME'            => ['inline', $name],
            "$name.m"         => ['on_disk', $source],
            'snowflake-build' => bash_strict(<<'BASH'),
                name=$(< NAME)

                # Make sure mmc can find the interface files.
                for dependency in "$@"; do
                    dependency_name=$(< "$dependency/NAME")
                    # mmc seems to ignore broken symlinks so even if some of
                    # these don’t exist it will still work fine.
                    ln --symbolic "$dependency/$dependency_name".int{,0,2,3} .
                done

                # Generate the interface files.
                mmc --make-short-int "$name".m
                mmc --make-priv-int "$name".m
                mmc --make-int "$name".m

                # Expose the interface files and the module name.
                mkdir snowflake-output
                mv NAME snowflake-output
                for int_file in "$name".int{,0,2,3}; do
                    if [[ -e $int_file ]]; then
                        mv "$int_file" snowflake-output
                    fi
                done
BASH
        },
    );

    my $implementation = Snowflake::Rule->new(
        name => "Mercury implementation ‘$name’",
        dependencies => [map { recursive_interfaces($_) } @dependencies],
        sources => {
            'NAME'            => ['inline', $name],
            "$name.m"         => ['on_disk', $source],
            'snowflake-build' => bash_strict(<<'BASH'),
                name=$(< NAME)

                # Make sure mmc can find the interface files.
                for dependency in "$@"; do
                    dependency_name=$(< "$dependency/NAME")
                    # mmc seems to ignore broken symlinks so even if some of
                    # these don’t exist it will still work fine.
                    ln --symbolic "$dependency/$dependency_name".int{,0,2,3} .
                done

                # Generate the init file and the object file.
                mmc -O6 -c "$name".m

                # Expose the init file and the object file.
                mkdir snowflake-output
                mv "$name".{c,o} snowflake-output
BASH
        },
    );

    { dependencies   => \@dependencies
    , interface      => $interface
    , implementation => $implementation };
}

=head2 mercury_executable(name => $name, modules => \@modules)

Link an executable named C<$name> from the modules C<\@modules>, which must
refer to an array of objects returned by C<mercury_module>. The executable is
emitted in the output directory of the rule with the given name as its
filename.

=cut

sub mercury_executable
{
    my %options = @_;
    my $name    = $options{name};
    my @modules = $options{modules}->@*;
    Snowflake::Rule->new(
        name => "Mercury executable ‘$name’",
        dependencies => [map { $_->{implementation} } @modules],
        sources => {
            'NAME'            => ['inline', $name],
            'snowflake-build' => bash_strict(<<'BASH'),
                name=$(< NAME)

                # Generate the arguments to c2init and ml.
                inits=()
                objects=()
                for dependency in "$@"; do
                    inits+=("$dependency"/*.c)
                    objects+=("$dependency"/*.o)
                done

                # Invoke the C compiler and the linker.
                c2init "${inits[@]}" > init.c
                mgnuc -O2 -c init.c
                ml -o "$name" "${objects[@]}" init.o

                # Expose the executable.
                mkdir snowflake-output
                mv "$name" snowflake-output
BASH
        },
    );
}

1;
