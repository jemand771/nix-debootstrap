{
  pkgs,
}:
rec {
  releaseFile =
    baseUrl: dist: hash:
    pkgs.fetchurl {
      url = "${baseUrl}dists/${dist}/Release";
      inherit hash;
    };
  listHashesFromRelease =
    baseUrl: dist: releaseHash:
    pkgs.runCommand "list-hashes-${dist}" { src = releaseFile baseUrl dist releaseHash; } ''
      grep -A99999 -m1 'SHA256:' $src | tail -n+2 | while read line; do
        hash=$(echo $line | cut -d" " -f1)
        filename=$out/$(echo $line | cut -d" " -f3)
        mkdir -p $(dirname $filename)
        echo -n $hash > $filename
      done
    '';
  packageList =
    compressor: ext: baseUrl: dist: releaseHash: component: flavor:
    let
      listPath = "${component}/${flavor}/Packages.${ext}";
    in
    "# ${baseUrl}\n"
    + builtins.readFile (
      builtins.toString (
        pkgs.runCommand "package-list-${dist}-${listPath}" {
          src = pkgs.fetchurl {
            url = "${baseUrl}dists/${dist}/${listPath}";
            sha256 = builtins.readFile "${listHashesFromRelease baseUrl dist releaseHash}/${listPath}";
          };
        } "${compressor} -d < $src > $out"
      )
    );
  packageListXz = packageList "xz" "xz";
  packageListGz = packageList "gzip" "gz";
}
