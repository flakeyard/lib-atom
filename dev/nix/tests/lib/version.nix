# lib.version: the version in .release-please-manifest.json.
{
  lib-atom,
  root,
  testing,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.test-lib-version = testing.facts pkgs "test-lib-version" {
        "the version is the manifest's" =
          lib-atom.version == (pkgs.lib.importJSON (root + "/.release-please-manifest.json"))."."
          && builtins.match "[0-9]+\\.[0-9]+\\.[0-9]+" lib-atom.version != null;
      };
    };
}
