package Snowflake::Config;

use strict;
use warnings;

use Carp qw(confess);
use Errno qw(EEXIST ENOENT);
use File::Path qw(mkpath);

use Class::Struct (
    stash_path => '$',
);

=head2 $config->scratch_path($build_hash)

Return the scratch path for a rule by its build hash. The scratch path refers
to the directory used temporarily for building a rule.

This subroutine does not ensure that the scratch path refers to an existing
file; in fact it does no I/O at all.

=cut

sub scratch_path
{
    my ($self, $build_hash) = @_;
    my $stash_path = $self->stash_path;
    "$stash_path/scratch/$build_hash";
}

=head2 $config->output_path($output_hash)

Return the path for a rule output by its output hash.

This subroutine does not ensure that the output path refers to an existing
file; in fact it does no I/O at all.

=cut

sub output_path
{
    my ($self, $output_hash) = @_;
    my $stash_path = $self->stash_path;
    "$stash_path/output/$output_hash";
}

=head2 $config->set_cache($build_hash, $output_hash)

Remember the rule with the given build hash as producing the output with the
given output hash. This is remembered even across invocations of the build
system.

=cut

sub set_cache
{
    my ($self, $build_hash, $output_hash) = @_;
    my $stash_path = $self->stash_path;
    mkpath("$stash_path/cache");
    symlink("../output/$output_hash", "$stash_path/cache/$build_hash")
        or do { confess($!) unless $!{EEXIST} };
    undef;
}

=head2 $config->get_cache($build_hash)

Get an output hash previously assigned with C<set_cache>, or undef if no such
entry exists.

=cut

sub get_cache
{
    my ($self, $build_hash) = @_;
    my $stash_path = $self->stash_path;
    my $path = readlink("$stash_path/cache/$build_hash");
    if (defined($path)) {
        $path =~ s#^\.\./output/##r;
    } elsif ($!{ENOENT}) {
        undef;
    } else {
        confess($!);
    }
}

1;
