{pkgs ? import ./nix/pkgs.nix {}}:
pkgs.callPackage ./snowflake.nix {}
