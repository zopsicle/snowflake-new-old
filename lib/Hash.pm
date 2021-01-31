=head1 NAME

Snowflake::Hash

=head2 DESCRIPTION

This module defines subroutines for computing hashes. This module is to be
read in tandem with C<Snowflake::Rule>, as it computes hashes of parts of
rules and rule outputs.

=cut

package Snowflake::Hash;

use strict;
use warnings;

use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use Exporter qw(import);

our @EXPORT_OK = qw(build_hash hash_file output_hash sources_hash);

=head2 hash_file($path)

Return a hash of the file at C<$path>. The hash includes the contents of the
file and the mode of the file. If the file is a directory, it is recursively
traversed.

=cut

sub hash_file
{
    my ($path) = @_;
    my $nix_hash_path = $ENV{SNOWFLAKE_NIX_HASH_PATH};
    open(my $stdout, '-|', $nix_hash_path, '--type', 'sha256', $path)
        or confess("open: $!");
    my $line = <$stdout>;
    if (defined($line)) {
        chomp($line);
        $line;
    } else {
        confess('nix-hash');
    }
}

=head2 sources_hash(%sources)

Return the sources hash of a rule from its sources.

=cut

sub sources_hash
{
    my %sources = @_;
    my $hash = Digest::SHA->new('sha256');
    for my $name (sort(keys(%sources))) {
        my ($type, $source) = $sources{$name}->@*;
        $hash->add($name);
        if ($type eq 'inline') {
            $hash->add($source);
        } elsif ($type eq 'on_disk') {
            $hash->add(hash_file($source));
        } elsif ($type eq 'on_disk_link') {
            $hash->add(hash_file($source));
        } else {
            confess("Bad source type: $type");
        }
    }
    $hash->hexdigest;
}

=head2 build_hash($sources_hash, @dependency_output_hashes)

Return the build hash of a rule from its sources hash and its dependency
output hashes. The build hash uniquely identifies a build, and it used as the
cache key.

=cut

sub build_hash
{
    goto &sha256_hex;
}

=head2 output_hash($output_path)

Return the output hash of a rule from its output path.

=cut

sub output_hash
{
    goto &hash_file;
}

1;
