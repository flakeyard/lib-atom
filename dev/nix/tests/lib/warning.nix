# lib.warning: the warning of the next major version (FY-0038), given with
# lib.warn while nix/next-major.nix exists, with the version and the guide it
# names; without the file, the value alone.
{
  lib-atom,
  root,
  testing,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) lib;
      # A lib.warn that returns what it was given.
      warning =
        root:
        lib-atom.warning {
          lib = lib // {
            warn = message: value: { inherit message value; };
          };
          atom = "atom-example";
          inherit root;
        } "value";
      warned = warning (root + "/internal/testing/fixtures/next-major");
    in
    {
      checks.test-lib-warning = testing.facts pkgs "test-lib-warning" {
        # Restated: the text is the interface (FY-0035).
        "the warning names the atom, the version and the guide" =
          warned.message == "atom-example: version 1 is coming with breaking changes;"
          + " support of this major version ends 6 months after its first release."
          + " Migration guide: https://github.com/flakeyard/atom-example/blob/main/docs/migration/v1.md";
        "the value is kept" = warned.value == "value";
        "no file, no warning" = warning (root + "/dev/fixtures/atom") == "value";
      };
    };
}
