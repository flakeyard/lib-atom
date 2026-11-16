# checks.test-next-major: the warning of the next major version (FY-0038).
# The atom's output warns, with the message that the atom's own module makes
# for a nix/next-major.nix as the maintainer adds it, and a real
# nix/next-major.nix of the atom names a version above the current one. The
# atom gets a lib-atom whose warning adds the message and the root that the
# atom passes to the output as lib-atom-warning, instead of warning.
{
  facts,
  fixture,
  root,
  lib-atom,
  announcing,
}:
{
  # The output of the fixture project good that warns, such as
  # [ "checks" "shell" ] for checks.<system>.shell.
  output,
  # The warning for version 1 with the guide docs/migration/v1.md, restated
  # by the atom's tests as its interface (FY-0035).
  message,
}:
{ pkgs, system, ... }:
let
  inherit (pkgs) lib;
  current = lib.toInt (
    lib.versions.major (lib.importJSON (root + "/.release-please-manifest.json"))."."
  );
  spied.lib = lib-atom // {
    warning =
      arguments: value:
      value
      // {
        lib-atom-warning = {
          inherit (arguments) root;
          message = lib-atom.warning (
            arguments
            // {
              lib = arguments.lib // {
                warn = message: _: message;
              };
              root = announcing;
            }
          ) null;
        };
      };
  };
  made =
    (lib.getAttrFromPath
      (
        [
          (lib.head output)
          system
        ]
        ++ lib.tail output
      )
      (fixture {
        name = "good";
        atomInputs.lib-atom = spied;
      })
    ).lib-atom-warning or null;
  real = root + "/nix/next-major.nix";
in
{
  checks.test-next-major = facts pkgs "test-next-major" {
    "the output warns" = made != null;
    "the warning names the version and the guide" = (made.message or null) == message;
    "the atom passes its root" = toString (made.root or "") == toString root;
    "nix/next-major.nix names a version above the current one" =
      !builtins.pathExists real || (import real).version > current;
  };
}
