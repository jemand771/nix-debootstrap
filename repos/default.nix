{ pkgs, ... }:
rec {
  forceList = val: if builtins.isList val then val else [ val ];
  # takes an attrset of strings
  packagesForSingleSingle =
    repo:
    {
      dist,
      component,
      flavor,
    }:
    builtins.fromJSON (builtins.readFile ./${repo}/${dist}_${component}_${flavor}.json);
  # takes an attrset of strings or string lists
  packagesForSingleMulti =
    repo: cfg:
    builtins.concatMap (packagesForSingleSingle repo) (
      pkgs.lib.cartesianProduct (builtins.mapAttrs (_: forceList) cfg)
    );
  # takes an attrset of strings or string lists, or a list containing such attrsets
  packagesForMultiMulti = repo: cfg: builtins.concatMap (packagesForSingleMulti repo) (forceList cfg);
  packagesFor = packagesForMultiMulti;
  debian.packagesFor = packagesFor "debian";
}
