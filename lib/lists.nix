{
  pkgs,
}:
rec {
  list2json =
    list:
    let
      split = pkgs.lib.splitString "\n" list;
      _baseUrl = pkgs.lib.removePrefix "# " (builtins.head split);
      unwrappedLines = builtins.map (
        line: if pkgs.lib.strings.hasPrefix " " line then line else "\n${line}"
      ) (builtins.tail split);
      fullFile = pkgs.lib.removeSuffix "\n" (
        pkgs.lib.removePrefix "\n" (pkgs.lib.concatStringsSep "" unwrappedLines)
      );
    in
    builtins.map (
      block:
      {
        inherit _baseUrl;
      }
      // builtins.listToAttrs (
        builtins.map (
          line:
          let
            split = pkgs.lib.splitString ": " line;
          in
          {
            name = builtins.elemAt split 0;
            value = pkgs.lib.concatStringsSep ": " (builtins.tail split);
          }
        ) (pkgs.lib.splitString "\n" block)
      )
    ) (builtins.filter (block: builtins.stringLength block > 0) (pkgs.lib.splitString "\n\n" fullFile));
  json2list =
    json:
    pkgs.lib.concatStringsSep "\n\n" (
      builtins.map (
        package:
        pkgs.lib.concatStringsSep "\n" (
          pkgs.lib.mapAttrsToList (name: value: "${name}: ${value}") (
            pkgs.lib.filterAttrs (name: _: !pkgs.lib.hasPrefix "_" name) package
          )
        )
      ) json
    );
  find =
    packages: name:
    # TODO auto-determine current build arch
    let
      arch =
        if pkgs.lib.hasInfix ":" name then pkgs.lib.last (pkgs.lib.splitString ":" name) else "amd64";
      pkgname =
        if pkgs.lib.hasInfix ":" name then pkgs.lib.head (pkgs.lib.splitString ":" name) else name;
    in
    pkgs.lib.findFirst (
      p: p.Package == pkgname && (p.Architecture == arch || p.Architecture == "all")
    ) null packages;
  findAll = packages: builtins.map (find packages);
  unfind = p: p.Package;
  unfindAll = builtins.map unfind;
}
