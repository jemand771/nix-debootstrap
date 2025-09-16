{ ... }:
{
  packagesFor =
    {
      dist,
      component,
      flavor,
    }:
    builtins.fromJSON (builtins.readFile ./${dist}_${component}_${flavor}.json);
}
