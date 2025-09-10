{
  pkgs,
  release,
}:
rec {
  baseUrl = "https://snapshot.debian.org/archive/debian/20250817T082947Z/";
  releaseHashes = {
    trixie = "sha256-SPJcH1gsULfUPTdIHZmcLlM3WW2UifKuMxROFK/kodk=";
    bullseye = "sha256-2y1Pv0P816CBJOf7w4fS6OJZnwGFiqfib26daKWDVlc=";
  };
  releaseFile = dist: release.releaseFile baseUrl dist (pkgs.lib.getAttr dist releaseHashes);
  listHashesFromRelease =
    dist: release.listHashesFromRelease baseUrl dist (pkgs.lib.getAttr dist releaseHashes);
  packageList =
    dist: component: flavor:
    release.packageListXz baseUrl dist (pkgs.lib.getAttr dist releaseHashes) component flavor;
}
