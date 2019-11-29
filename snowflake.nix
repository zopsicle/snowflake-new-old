{stdenvNoCC, makeWrapper, bash, coreutils, nix, perl}:
let
    perlWithPackages = perl.withPackages (p: [
        p.DBDSQLite
        p.DBI
    ]);
in
stdenvNoCC.mkDerivation rec {
    name = "snowflake-${version}";
    version = "0.0.0";

    buildInputs = [makeWrapper];

    phases = ["unpackPhase" "installPhase"];

    unpackPhase = ''
        mkdir --parents $out/share/lib
        cp --recursive ${./bin} $out/share/bin
        cp --recursive ${./lib} $out/share/lib/Snowflake
    '';

    installPhase = ''
        mkdir --parents $out/bin
        makeWrapper ${perlWithPackages}/bin/perl $out/bin/snowflake \
            --set SNOWFLAKE_BASH_PATH     ${bash}/bin/bash \
            --set SNOWFLAKE_CP_PATH       ${coreutils}/bin/cp \
            --set SNOWFLAKE_NIX_HASH_PATH ${nix}/bin/nix-hash \
            --set SNOWFLAKE_LIB_PATH      $out/share/lib \
            --add-flags $out/share/bin/snowflake.pl
    '';
}
