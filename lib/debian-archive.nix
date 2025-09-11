{
  pkgs,
  release,
}:
rec {
  baseUrl = "https://archive.debian.org/debian/";
  releaseHashes = {
    bullseye-backports = "sha256-x0tlQ4j0tU5SaBIqEU9L68qx8pbLnvjY3wKsxrJoF0Q=";
  };
  releaseFile = dist: release.releaseFile baseUrl dist (pkgs.lib.getAttr dist releaseHashes);
  listHashesFromRelease =
    dist: release.listHashesFromRelease baseUrl dist (pkgs.lib.getAttr dist releaseHashes);
  packageList =
    dist: component: flavor:
    release.packageListXz baseUrl dist (pkgs.lib.getAttr dist releaseHashes) component flavor;
}
