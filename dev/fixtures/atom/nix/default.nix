# The root module of atom-example: the guarded imports of treefmt-nix and
# git-hooks.nix, the formatter shfmt and devShells.flakeyard-example, which
# warns while nix/next-major.nix exists. The input example can give it
# another name or drop the guard, as a broken atom would.
atomInputs:
{ inputs, ... }:
let
  root = ./..;
  shared = atomInputs.lib-atom.lib;
  example = {
    name = "atom-example";
    guarded = true;
  }
  // atomInputs.example or { };
  upstream =
    if example.guarded then
      shared.upstream {
        atom = example.name;
        own = atomInputs;
        consumer = inputs;
      }
    else
      _: module: module;
in
{
  key = toString ./default.nix;
  _file = ./default.nix;
  imports = [
    (upstream "treefmt-nix" atomInputs.treefmt-nix.flakeModule)
    (upstream "git-hooks" atomInputs.git-hooks.flakeModule)
  ];
  perSystem =
    { pkgs, ... }:
    {
      treefmt.programs.shfmt = {
        enable = pkgs.lib.mkOverride 900 true;
        package = pkgs.lib.mkOverride 900 pkgs.shfmt;
      };
      devShells.flakeyard-example = shared.warning {
        inherit (pkgs) lib;
        atom = example.name;
        inherit root;
      } (pkgs.mkShellNoCC { packages = [ pkgs.shfmt ]; });
    };
}
