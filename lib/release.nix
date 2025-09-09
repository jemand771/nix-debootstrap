{
  pkgs,
  baseUrl,
}:
rec {
  releaseHashes = {
    trixie = "sha256-SPJcH1gsULfUPTdIHZmcLlM3WW2UifKuMxROFK/kodk=";
  };
  releaseFile =
    dist:
    pkgs.fetchurl {
      url = "${baseUrl}dists/${dist}/Release";
      hash = pkgs.lib.getAttr dist releaseHashes;
    };
  listHashesFromRelease =
    dist:
    pkgs.runCommand "list-hashes-${dist}" { src = releaseFile dist; } ''
      grep -A99999 -m1 'SHA256:' $src | tail -n+2 | while read line; do
        hash=$(echo $line | cut -d" " -f1)
        filename=$out/$(echo $line | cut -d" " -f3)
        mkdir -p $(dirname $filename)
        echo -n $hash > $filename
      done
    '';
  packageList =
    dist: component: flavor:
    let
      listPath = "${component}/${flavor}/Packages.xz";
    in
    builtins.readFile (
      builtins.toString (
        pkgs.runCommand "package-list-${dist}-${listPath}" {
          src = pkgs.fetchurl {
            url = "${baseUrl}dists/${dist}/${listPath}";
            sha256 = builtins.readFile "${listHashesFromRelease dist}/${listPath}";
          };
        } "xz -d < $src > $out"
      )
    );
}
