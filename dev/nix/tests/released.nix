# The tests of the released atoms with the working tree of lib-atom in place
# of the revision they pin (FY-0040): checks.test-released-<atom> builds every
# check of the atom's dev flake at the revision that this flake locks, with
# the inputs that the atom's dev/flake.lock locks.
#
# The loader in an atom's dev/flake.nix fetches lib-atom with
# builtins.fetchTree from the node of the atom's root flake.lock, and nothing
# can override that from outside the atom. The dev flake is therefore
# imported with builtins.scopedImport and a builtins whose fetchTree gives
# the root of this repository for that node; every other file of the atom is
# imported as usual. A fact fails the check when the atom no longer pins
# lib-atom or its loader no longer calls builtins.fetchTree, which would leave
# the pinned revision in place.
{
  inputs,
  lib,
  root,
  testing,
  ...
}:
let
  # The released atoms, by input of this flake; a newly released atom is
  # added here and as an input.
  atoms = [
    "atom-workflows"
    "atom-workspace"
    "atom-nix"
    "atom-shell"
    "atom-markdown"
    "atom-text"
    "atom-data-formats"
  ];
  libAtomUrl = "https://github.com/flakeyard/lib-atom";
  released =
    name:
    let
      source = inputs.${name};
      # The atom's dev flake as Nix locks it, for its inputs; its outputs are
      # not used, since they take the pinned lib-atom.
      pinned = builtins.getFlake "git+https://github.com/flakeyard/${name}?dir=dev&rev=${source.rev}&shallow=1";
      lock = builtins.fromJSON (builtins.readFile (source + "/flake.lock"));
      loader = builtins.readFile (source + "/dev/flake.nix");
      fetchTree =
        locked:
        if locked.url or null == libAtomUrl then
          root
        else
          throw "${name}: dev/flake.nix fetches ${locked.url or "a source"} with builtins.fetchTree; only lib-atom is expected";
      scope.builtins = builtins // {
        inherit fetchTree;
      };
      flake = builtins.scopedImport scope (source + "/dev/flake.nix");
      # The flake as Nix gives it to its own outputs as self.
      self =
        pinned.sourceInfo
        // {
          inherit (pinned) outPath inputs;
          inherit outputs;
          _type = "flake";
        }
        // outputs;
      outputs = flake.outputs (pinned.inputs // { inherit self; });
    in
    {
      inherit outputs;
      facts = {
        "${name} pins lib-atom in its root flake.lock" =
          (lock.nodes.${lock.nodes.root.inputs.lib-atom or ""}.locked.url or null) == libAtomUrl;
        "the loader of ${name} fetches lib-atom with builtins.fetchTree" =
          lib.hasInfix "builtins.fetchTree lock.nodes.\${lock.nodes.root.inputs.lib-atom}.locked" loader;
      };
    };
in
{
  perSystem =
    { pkgs, system, ... }:
    {
      checks = lib.genAttrs' atoms (
        name:
        let
          atom = released name;
          facts = testing.facts pkgs "test-released-${name}-facts" atom.facts;
        in
        lib.nameValuePair "test-released-${name}" (
          pkgs.linkFarm "test-released-${name}" (
            [
              {
                name = "facts";
                path = facts;
              }
            ]
            ++ lib.mapAttrsToList (check: path: {
              name = check;
              inherit path;
            }) atom.outputs.checks.${system}
          )
        )
      );
    };
}
