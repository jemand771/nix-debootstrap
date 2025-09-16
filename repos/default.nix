{ ... }:
rec {
  packagesFor =
    repo:
    {
      dist,
      component,
      flavor,
    }:
    builtins.fromJSON (builtins.readFile ./${repo}/${dist}_${component}_${flavor}.json);
  debian.packagesFor = packagesFor "debian";
}
