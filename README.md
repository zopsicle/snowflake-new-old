<img align="right" src="marketing/logo.svg" width="144">

Snowflake
=========

Snowflake is a language-agnostic build system
that aims to implement caching correctly.

Highlights
----------

 - Robust caching mechanism based on cryptographic hashes.
 - Language-agnostic build system with no assumed conventions.
 - Configurable with highly expressive [Perl][perl] programming language.
 - Built on a small number of simple core concepts.

[perl]: https://www.perl.org

Installation
------------

As with all software, Snowflake is best installed with [Nix][nix].
The file _default.nix_ in this repository evaluates to a derivation
that builds a self-contained Snowflake executable in the Nix store.

[nix]: https://nixos.org/nix/

Example
-------

For an example, see the _example_ directory.
The _example_ directory contains a file _build.pl_
which you may pass to Snowflake as shown in figure 1.
This will build the example source code,
yielding an executable in _build/artifact/hello_.

Figure 1:

```bash
snowflake example/build.pl
```

License
-------

You are licensed to redistribute and use Snowflake
under the terms of the 3-Clause BSD License.
See the file _COPYING.md_ for more information.
