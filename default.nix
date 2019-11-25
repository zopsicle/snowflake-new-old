{pkgs ? import ./nix/pkgs.nix {}}:
pkgs.stdenvNoCC.mkDerivation rec {
    name = "snowflake-${version}";
    version = "0.0.0";

    buildInputs = [pkgs.makeWrapper];

    phases = ["unpackPhase" "installPhase"];

    unpackPhase = ''
        mkdir --parents $out/share/lib
        cp --recursive ${./bin} $out/share/bin
        cp --recursive ${./lib} $out/share/lib/Snowflake
    '';

    installPhase = ''
        mkdir --parents $out/bin
        makeWrapper ${pkgs.perl}/bin/perl $out/bin/snowflake \
            --set SNOWFLAKE_BASH_PATH     ${pkgs.bash}/bin/bash \
            --set SNOWFLAKE_NIX_HASH_PATH ${pkgs.nix}/bin/nix-hash \
            --set SNOWFLAKE_RSYNC_PATH    ${pkgs.rsync}/bin/rsync \
            --set PERL5LIB $out/share/lib \
            --add-flags $out/share/bin/snowflake.pl
    '';
}
